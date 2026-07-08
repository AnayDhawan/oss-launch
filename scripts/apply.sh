#!/usr/bin/env bash
# apply.sh — headless OSS scaffolding, no agent loop required.
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

CREATED=(); SKIPPED=(); MANUAL=()

# --- 0. scan ---
STACK="$(detect_stack "$DIR")"

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
  local rel="$1" src="$2" dest="$DIR/$1"
  if [ -e "$dest" ]; then SKIPPED+=("$rel"); return; fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  fill "$dest"
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
[ "$WANT_CITATION" = "true" ] && write "CITATION.cff" "$TPL/CITATION.cff"
[ "$WANT_FUNDING" = "true" ] && write ".github/FUNDING.yml" "$TPL/FUNDING.yml"

write ".github/ISSUE_TEMPLATE/config.yml" "$TPL/.github/ISSUE_TEMPLATE/config.yml"
write ".github/ISSUE_TEMPLATE/bug_report.yml" "$TPL/.github/ISSUE_TEMPLATE/bug_report.yml"
write ".github/ISSUE_TEMPLATE/feature_request.yml" "$TPL/.github/ISSUE_TEMPLATE/feature_request.yml"
write ".github/PULL_REQUEST_TEMPLATE.md" "$TPL/.github/PULL_REQUEST_TEMPLATE.md"
write ".github/dependabot.yml" "$TPL/.github/dependabot.yml"
write ".github/workflows/ci.yml" "$TPL/$(stack_ci_file "$STACK")"

if [ ! -f "$DIR/README.md" ]; then
  MANUAL+=("README.md -- prose generation is an agent-only step, see references/generate.md; run /oss-launch or write by hand")
fi

# --- 4. re-audit ---
echo ""
echo "── apply.sh summary (stack: $STACK) ──"
echo "Created (${#CREATED[@]}): ${CREATED[*]:-none}"
echo "Skipped, already existed (${#SKIPPED[@]}): ${SKIPPED[*]:-none}"
[ ${#MANUAL[@]} -gt 0 ] && printf 'Manual TODO: %s\n' "${MANUAL[@]}"
echo ""
bash "$ROOT/scripts/audit.sh" "$DIR"
