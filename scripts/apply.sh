#!/usr/bin/env bash
# apply.sh: headless OSS scaffolding, no agent loop required.
# Runs SKILL.md steps 0 (scan) + 3 (generate) + 4 (re-audit) deterministically, from a
# config file instead of an agent Q&A round. See templates/oss-launch.config.example.
#
# Usage:
#   bash scripts/apply.sh <target-dir> [--config <file>]
#
# Never overwrites an existing file (see "Don't-overwrite protocol" in generate.md) --
# headless mode has no one to show a diff to, so the safe default is skip + report,
# not clobber. README.md prose generation is an agent-only step (see generate.md's
# mode split); apply.sh does not fabricate marketing copy, and reports it as manual.
#
# shellcheck disable=SC2034  # several vars below are consumed by fill() in
# scripts/lib/fill-templates.sh, which shellcheck can't statically resolve through
# the dynamic $ROOT path.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$ROOT/templates"
# shellcheck source=scripts/lib/detect-stack.sh
source "$ROOT/scripts/lib/detect-stack.sh"
# shellcheck source=scripts/lib/detect-site.sh
source "$ROOT/scripts/lib/detect-site.sh"
# shellcheck source=scripts/lib/fill-templates.sh
source "$ROOT/scripts/lib/fill-templates.sh"

DIR="${1:-}"
CONFIG=""
if [ "${2:-}" = "--config" ]; then CONFIG="${3:-}"; fi
if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "usage: apply.sh <target-dir> [--config <file>]" >&2
  exit 1
fi
DIR="$(cd "$DIR" && pwd)"

# Generated files land in STAGE first, not $DIR directly. A crash mid-generation (a
# missing template, a fill() failure on some stack's command table) then leaves the
# target repo untouched instead of holding whichever files happened to write before the
# failure. The "never overwrites an existing file" check below still reads real $DIR, so
# skip decisions are unaffected; only the write destination moves.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

CREATED=(); SKIPPED=(); MANUAL=()

# --- 0. scan ---
STACK="$(detect_stack "$DIR")"
# Orthogonal to STACK: a repo is one primary language AND possibly a workspace AND
# possibly containerised. Surfaced as setup notes rather than changing which templates
# are written -- see the summary section at the bottom.
MONOREPO="$(detect_monorepo "$DIR")"
DOCKER="$(detect_docker "$DIR")"
# Non-empty only when a static-site/docs framework or GitHub Pages is clearly present.
SITE_FRAMEWORK="$(detect_site_framework "$DIR")"

REMOTE_URL="$(git -C "$DIR" remote get-url origin 2>/dev/null || true)"
OWNER=""; REPO=""
if [ -n "$REMOTE_URL" ]; then
  # normalize scp-like ssh syntax (git@host:owner/repo) to slash form, then
  # basename/dirname handles both that and https://host/owner/repo uniformly
  NORMALIZED_URL="${REMOTE_URL%.git}"
  NORMALIZED_URL="$(printf '%s' "$NORMALIZED_URL" | sed -E 's#^[a-zA-Z0-9._-]+@([^:/]+):#https://\1/#')"
  REPO="$(basename "$NORMALIZED_URL")"
  OWNER="$(basename "$(dirname "$NORMALIZED_URL")")"
fi
[ -z "$REPO" ] && REPO="$(basename "$DIR")"

VERSION=""
if [ -f "$DIR/package.json" ]; then
  VERSION="$(grep -m1 '"version"' "$DIR/package.json" | sed -E 's/.*"version"\s*:\s*"([^"]+)".*/\1/')"
elif [ -f "$DIR/pyproject.toml" ]; then
  # same regex release.sh's get_current_version() uses for the python case
  VERSION="$(grep '^version' "$DIR/pyproject.toml" | head -1 | sed 's/.*= *"\(.*\)"/\1/')"
elif [ -f "$DIR/Cargo.toml" ]; then
  VERSION="$(grep -m1 '^version' "$DIR/Cargo.toml" | sed -E 's/version\s*=\s*"([^"]+)"/\1/')"
fi
[ -z "$VERSION" ] && VERSION="$(git -C "$DIR" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)"
[ -z "$VERSION" ] && VERSION="0.1.0"

YEAR="$(date +%Y)"

# --- load config (overrides any of the above, supplies what can't be inferred) ---
if [ -n "$CONFIG" ]; then
  [ -f "$CONFIG" ] || { echo "Config file not found: $CONFIG" >&2; exit 1; }
  # shellcheck disable=SC1090
  source "$CONFIG"
fi

# --- required fields: fail clearly rather than fabricate ---
MISSING=()
[ -z "${AUTHOR:-}" ] && MISSING+=("AUTHOR")
[ -z "${SECURITY_EMAIL:-}" ] && MISSING+=("SECURITY_EMAIL")
[ -z "${TAGLINE:-}" ] && MISSING+=("TAGLINE")
[ -z "$OWNER" ] && MISSING+=("OWNER (no git remote found -- set it in the config)")
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing required config values: ${MISSING[*]}" >&2
  echo "See templates/oss-launch.config.example for the config file format." >&2
  exit 1
fi

# --- defaults for everything else ---
default_var LICENSE "Apache-2.0"
default_var PROJECT_NAME "$REPO"
default_var CONTACT_EMAIL "$SECURITY_EMAIL"
default_var WANT_CITATION "false"
default_var WANT_FUNDING "false"
default_var WANT_COVERAGE "false"
default_var WANT_RELEASE_PLEASE "false"
default_var WANT_CONTAINER_BUILD "false"
# Base URL for the generated site files. GitHub Pages' project-site default; override in
# the config for a custom domain. Trailing slash matters, robots.txt and sitemap.xml both
# concatenate onto it.
default_var SITE_URL "https://$OWNER.github.io/$REPO/"
ECOSYSTEM="$(stack_ecosystem "$STACK")"
INSTALL_COMMAND="$(stack_install_cmd "$STACK")"
DEV_START_COMMAND="$(stack_dev_cmd "$STACK")"
VERIFY_COMMAND="$(stack_verify_cmd "$STACK")"
TEST_COMMAND="$(stack_test_cmd "$STACK")"
if [ -f "$DIR/.env.example" ]; then COPY_ENV_COMMAND="cp .env.example .env"
else COPY_ENV_COMMAND="(no .env required)"; fi
default_var SETUP_NOTES "See README.md Quick Start for setup."
default_var GOOD_FIRST_ISSUES_LIST "Check the issues tab for the current list."
default_var STYLE_RULE_1 "Match the existing code style in this repo."
default_var STYLE_RULE_2 "Keep functions small and single-purpose."
default_var STYLE_RULE_3 "Add a test for any new behavior."
default_var PROJECT_SPECIFIC_PR_RULE "Keep changes focused and include a clear description."
default_var COMMUNITY_LINK "Open an issue or discussion on GitHub."
CURRENT_MAJOR="${VERSION%%.*}"
INITIAL_VERSION="$VERSION"
RELEASE_DATE="$(date +%Y-%m-%d)"
default_var INITIAL_FEATURE_1 "Initial public release."
default_var INITIAL_FEATURE_2 "See README for details."

# --- 3. generate (skip anything that already exists -- see file header) ---
write() {  # write <relative-path-in-target> <source-template-path>
  local rel="$1" src="$2" dest="$DIR/$1" staged="$STAGE/$1"
  if [ -e "$dest" ]; then SKIPPED+=("$rel"); return; fi
  mkdir -p "$(dirname "$staged")"
  cp "$src" "$staged"
  fill "$staged"
  CREATED+=("$rel")
}

if [ "$LICENSE" = "MIT" ]; then write "LICENSE" "$TPL/LICENSE-mit.txt"
else write "LICENSE" "$TPL/LICENSE-apache.txt"; fi

write "CONTRIBUTING.md" "$TPL/CONTRIBUTING.md"
write "CODE_OF_CONDUCT.md" "$TPL/CODE_OF_CONDUCT.md"
write "SECURITY.md" "$TPL/SECURITY.md"
write "CHANGELOG.md" "$TPL/CHANGELOG.md"
write ".gitignore" "$TPL/$(stack_gitignore_file "$STACK")"
write ".editorconfig" "$TPL/.editorconfig"

# llms.txt describes the project, not a site, so it is written regardless of detection.
write "llms.txt" "$TPL/llms.txt"
# The site files only make sense where something is actually published. A robots.txt
# pointing at a sitemap that 404s is worse than no robots.txt at all.
if [ -n "$SITE_FRAMEWORK" ]; then
  write "404.html" "$TPL/site/404.html"
  write "robots.txt" "$TPL/site/robots.txt"
  write "sitemap.xml" "$TPL/site/sitemap.xml"
  MANUAL+=("Site files assume SITE_URL=$SITE_URL -- override it in the config if the site is on a custom domain, and expand sitemap.xml beyond the homepage stub")
fi
[ "$WANT_CITATION" = "true" ] && write "CITATION.cff" "$TPL/CITATION.cff"
[ "$WANT_FUNDING" = "true" ] && write ".github/FUNDING.yml" "$TPL/FUNDING.yml"

write ".github/ISSUE_TEMPLATE/config.yml" "$TPL/.github/ISSUE_TEMPLATE/config.yml"
write ".github/ISSUE_TEMPLATE/bug_report.yml" "$TPL/.github/ISSUE_TEMPLATE/bug_report.yml"
write ".github/ISSUE_TEMPLATE/feature_request.yml" "$TPL/.github/ISSUE_TEMPLATE/feature_request.yml"
write ".github/PULL_REQUEST_TEMPLATE.md" "$TPL/.github/PULL_REQUEST_TEMPLATE.md"
write ".github/dependabot.yml" "$TPL/.github/dependabot.yml"
if [ "$STACK" = "generic" ]; then
  # generic-ci.yml only lints shell scripts; on a repo with none (docs, data, a
  # config-only project) that's a workflow that runs and does nothing. Skip it
  # rather than ship a CI badge that's lying about coverage.
  MANUAL+=("No CI workflow written -- detected stack is generic (no build/test command known). Once there's something to run, copy $TPL/.github/workflows/generic-ci.yml and fill in a real test step, or re-run apply.sh after adding a manifest apply.sh recognizes.")
else
  write ".github/workflows/ci.yml" "$TPL/$(stack_ci_file "$STACK")"
fi

# Triage automation. Unconditional, unlike the opt-in workflows below: path-based
# labeling is inert until a PR touches a matching path, and the stale windows are long
# enough (90 days to warn, 30 more to close, PRs never auto-closed) that they cost a
# quiet repo nothing.
write ".github/labeler.yml" "$TPL/.github/labeler.yml"
write ".github/workflows/labeler.yml" "$TPL/.github/workflows/labeler.yml"
write ".github/workflows/stale.yml" "$TPL/.github/workflows/stale.yml"

# --- opt-in workflows (default false, same pattern as WANT_CITATION/WANT_FUNDING) ---
# Each one is gated on a real precondition as well as the flag, and says so out loud when
# the flag is set but the precondition is not met -- a silent no-op is worse than a note.

if [ "$WANT_COVERAGE" = "true" ]; then
  COVERAGE_TPL=""
  case "$STACK" in
    node)   COVERAGE_TPL=".github/workflows/coverage-node.yml" ;;
    python) COVERAGE_TPL=".github/workflows/coverage-python.yml" ;;
  esac
  if [ -z "$COVERAGE_TPL" ]; then
    MANUAL+=("WANT_COVERAGE=true, but there is no coverage template for the '$STACK' stack (node and python only)")
  elif [ "$VERIFY_COMMAND" = "(add your test command here)" ]; then
    MANUAL+=("WANT_COVERAGE=true, but no test runner was detected -- a coverage workflow with nothing to measure just fails CI")
  else
    write ".github/workflows/coverage.yml" "$TPL/$COVERAGE_TPL"
  fi
fi

if [ "$WANT_RELEASE_PLEASE" = "true" ]; then
  write ".github/workflows/release-please.yml" "$TPL/.github/workflows/release-please.yml"
  MANUAL+=("release-please.yml: set 'release-type' to match this project, and pick ONE release flow -- it and scripts/release.sh both own the version number and the CHANGELOG")
fi

if [ "$WANT_CONTAINER_BUILD" = "true" ]; then
  if [ -z "$DOCKER" ]; then
    MANUAL+=("WANT_CONTAINER_BUILD=true, but no Dockerfile or compose file was found -- nothing to build")
  else
    write ".github/workflows/container-build.yml" "$TPL/.github/workflows/container-build.yml"
  fi
fi

if [ ! -f "$DIR/README.md" ]; then
  MANUAL+=("README.md -- prose generation is an agent-only step, see references/generate.md; run /oss-launch or write by hand")
fi
MANUAL+=("Labels: run 'bash scripts/setup-labels.sh ${OWNER}/${REPO}' -- .github/labeler.yml references labels that must exist first")

# --- commit: move everything from STAGE into $DIR now that generation finished without
# error. This is the only loop that touches the target repo; every path in CREATED
# already rendered successfully once, so this is data movement, not generation. ---
for rel in "${CREATED[@]}"; do
  mkdir -p "$DIR/$(dirname "$rel")"
  cp "$STAGE/$rel" "$DIR/$rel"
done

# --- 4. re-audit ---
DETECTED="stack: $STACK"
[ -n "$MONOREPO" ] && DETECTED="$DETECTED, $MONOREPO monorepo"
[ -n "$DOCKER" ] && DETECTED="$DETECTED, Docker"
[ -n "$SITE_FRAMEWORK" ] && DETECTED="$DETECTED, $SITE_FRAMEWORK site"

echo ""
echo "── apply.sh summary ($DETECTED) ──"
echo "Created (${#CREATED[@]}): ${CREATED[*]:-none}"
echo "Skipped, already existed (${#SKIPPED[@]}): ${SKIPPED[*]:-none}"
[ ${#MANUAL[@]} -gt 0 ] && printf 'Manual TODO: %s\n' "${MANUAL[@]}"

if [ -n "$MONOREPO" ] || [ -n "$DOCKER" ]; then
  echo ""
  echo "── Notes ──"
fi
if [ -n "$MONOREPO" ]; then
  echo "Workspace detected ($MONOREPO). The generated CONTRIBUTING.md install and test"
  echo "commands target the repo root; a workspace usually needs a package filter"
  echo "(e.g. a --filter/-w flag, or running from the package dir). Review them, and"
  echo "consider a per-package 'directory:' entry in .github/dependabot.yml -- the"
  echo "generated config only watches '/'."
fi
if [ -n "$DOCKER" ]; then
  echo "Docker detected. The generated CI workflow does not build the image."
  if [ "$WANT_CONTAINER_BUILD" != "true" ]; then
    echo "Set WANT_CONTAINER_BUILD=true in the config for a GHCR build+push job"
    echo "(builds on PRs, pushes only from main and tags). See references/ci-cd.md."
  fi
  echo "Also worth adding a 'docker' ecosystem entry to .github/dependabot.yml so"
  echo "base-image updates are tracked."
fi
echo ""
bash "$ROOT/scripts/audit.sh" "$DIR"
