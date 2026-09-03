#!/usr/bin/env bash
# OSS Audit Script: checks what standard OSS files are missing.
# Usage: bash scripts/audit.sh [REPO_PATH]   (defaults to current directory)
# Resolves its own templates dir, so it runs from a clone or the installed skill.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$ROOT/templates"
# Used only to decide whether the site-file block in "Optional" is worth printing at all.
# shellcheck source=scripts/lib/detect-site.sh
source "$ROOT/scripts/lib/detect-site.sh"

REPO="${1:-.}"
if [ ! -d "$REPO" ]; then
  echo "audit.sh: repo path not found: $REPO" >&2
  echo "Usage: bash scripts/audit.sh [REPO_PATH]   (defaults to current directory)" >&2
  exit 2
fi

PASS="✓"
FAIL="✗"
WARN="⚠"
SCORE=0
TOTAL=0

green()  { printf "\033[0;32m%s\033[0m\n" "$*"; }
red()    { printf "\033[0;31m%s\033[0m\n" "$*"; }
yellow() { printf "\033[0;33m%s\033[0m\n" "$*"; }
bold()   { printf "\033[1m%s\033[0m\n" "$*"; }

check() {
  local label="$1" path="$2" fix="$3"
  TOTAL=$((TOTAL + 1))
  if [ -e "$REPO/$path" ]; then
    green "  $PASS  $label"
    SCORE=$((SCORE + 1))
  else
    red "  $FAIL  $label"
    yellow "       Fix: $fix"
  fi
}

# report-only, does not affect score: for situational files that aren't always relevant
check_optional() {
  local label="$1" path="$2" fix="$3"
  if [ -e "$REPO/$path" ]; then
    green "  $PASS  $label"
  else
    yellow "  $WARN  $label (optional)"
    yellow "       Fix: $fix"
  fi
}

# pass if ANY of the given paths exist (e.g. .yml or .md variants)
check_any() {
  local label="$1" fix="$2"; shift 2
  local found=0 p
  TOTAL=$((TOTAL + 1))
  for p in "$@"; do
    # shellcheck disable=SC2086  # $p may be a glob pattern we want expanded
    if ls "$REPO/"$p >/dev/null 2>&1; then found=1; break; fi
  done
  if [ "$found" -eq 1 ]; then
    green "  $PASS  $label"
    SCORE=$((SCORE + 1))
  else
    red "  $FAIL  $label"
    yellow "       Fix: $fix"
  fi
}

# Print only README content that can render: HTML comments and fenced examples
# must not satisfy audit checks merely by mentioning image or badge syntax.
rendered_readme() {
  if [ ! -f "$REPO/README.md" ]; then
    return 0
  fi

  awk '
    BEGIN { in_comment = 0; fence = "" }
    {
      line = $0

      while (1) {
        if (in_comment) {
          comment_end = index(line, "-->")
          if (comment_end == 0) {
            line = ""
            break
          }
          line = substr(line, comment_end + 3)
          in_comment = 0
        }

        comment_start = index(line, "<!--")
        if (comment_start == 0) break

        before_comment = substr(line, 1, comment_start - 1)
        after_comment = substr(line, comment_start + 4)
        comment_end = index(after_comment, "-->")
        if (comment_end == 0) {
          line = before_comment
          in_comment = 1
          break
        }
        line = before_comment substr(after_comment, comment_end + 3)
      }

      if (fence == "backtick") {
        if (line ~ /^[[:space:]]*```/) fence = ""
        next
      }
      if (fence == "tilde") {
        if (line ~ /^[[:space:]]*~~~/) fence = ""
        next
      }
      if (line ~ /^[[:space:]]*```/) {
        fence = "backtick"
        next
      }
      if (line ~ /^[[:space:]]*~~~/) {
        fence = "tilde"
        next
      }

      print line
    }
  ' "$REPO/README.md" 2>/dev/null
}

# Print the shell body of every `run:` step in a workflow file, inline or block scalar.
# Used to judge whether a workflow actually runs anything, rather than trusting that a
# file under .github/workflows/ must be CI.
run_steps_of() {  # run_steps_of <workflow-file>
  awk '
    BEGIN { in_block = 0; block_indent = 0 }
    {
      line = $0
      if (in_block) {
        if (line ~ /^[[:space:]]*$/) next
        match(line, /^[[:space:]]*/)
        if (RLENGTH > block_indent) { print line; next }
        in_block = 0
      }
      if (match(line, /^[[:space:]]*(-[[:space:]]*)?run:[[:space:]]*[|>][-+0-9]*[[:space:]]*$/)) {
        match(line, /^[[:space:]]*/)
        block_indent = RLENGTH
        in_block = 1
        next
      }
      if (match(line, /^[[:space:]]*(-[[:space:]]*)?run:[[:space:]]*/)) {
        print substr(line, RSTART + RLENGTH)
        next
      }
    }
  ' "$1" 2>/dev/null
}

# A workflow counts as CI when it demonstrably builds, tests, or lints:
#   - a `run:` step invoking a recognized build/test/lint tool, or
#   - a language-toolchain setup action, which a triage-only workflow has no reason to use.
# Triage automation (labeler.yml, stale.yml) has neither, so a repo whose only workflow is
# one of those no longer scores this point on the strength of the filename alone.
BUILD_VERBS='(^|[^[:alnum:]_./-])(npm|yarn|pnpm|npx|bun|pytest|tox|nox|unittest|cargo|go|mvn|gradle|gradlew|dotnet|bundle|rake|composer|phpunit|swift|make|cmake|ctest|ruff|flake8|pylint|mypy|black|eslint|prettier|shellcheck|clippy|gofmt|golangci-lint|rubocop|ktlint|detekt|sbt|tsc|jest|vitest|pytest-cov)([^[:alnum:]_-]|$)'
TOOLCHAIN_ACTIONS='uses:[[:space:]]*[^[:space:]]*(setup-(node|python|go|java|dotnet|ruby|php|swift|haskell)|rust-toolchain|setup-bun|setup-pnpm)'

has_real_ci_workflow() {
  local f
  for f in "$REPO"/.github/workflows/*.yml "$REPO"/.github/workflows/*.yaml; do
    [ -f "$f" ] || continue
    grep -Eqi "$TOOLCHAIN_ACTIONS" "$f" && return 0
    run_steps_of "$f" | grep -Eqi "$BUILD_VERBS" && return 0
  done
  return 1
}

echo ""
bold "OSS Audit: $REPO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
bold "── Core Files ──"
check "README.md"          "README.md"          "Create from $TPL/README.md"
check "LICENSE"            "LICENSE"            "Copy $TPL/LICENSE-apache.txt (or LICENSE-mit.txt) and fill year/author"
check "CONTRIBUTING.md"    "CONTRIBUTING.md"    "Copy $TPL/CONTRIBUTING.md"
check "SECURITY.md"        "SECURITY.md"        "Copy $TPL/SECURITY.md"
check "CODE_OF_CONDUCT.md" "CODE_OF_CONDUCT.md" "Copy $TPL/CODE_OF_CONDUCT.md"
check "CHANGELOG.md"       "CHANGELOG.md"       "Copy $TPL/CHANGELOG.md"
check_any ".gitignore" "Copy a variant from $TPL/gitignore/" ".gitignore"

echo ""
bold "── GitHub Templates ──"
check_any "Issue template: bug"     "Copy $TPL/.github/ISSUE_TEMPLATE/bug_report.yml" \
  ".github/ISSUE_TEMPLATE/bug*"
check_any "Issue template: feature" "Copy $TPL/.github/ISSUE_TEMPLATE/feature_request.yml" \
  ".github/ISSUE_TEMPLATE/feature*" ".github/ISSUE_TEMPLATE/enhancement*" ".github/ISSUE_TEMPLATE/new_*"
check_any "PR template" "Copy $TPL/.github/PULL_REQUEST_TEMPLATE.md" \
  ".github/PULL_REQUEST_TEMPLATE.md" ".github/pull_request_template.md"
check "Dependabot config" ".github/dependabot.yml" "Copy $TPL/.github/dependabot.yml"

echo ""
bold "── Workflows ──"
TOTAL=$((TOTAL + 1))
if [ -d "$REPO/.github/workflows" ]; then
  green "  $PASS  .github/workflows/ directory exists"
  SCORE=$((SCORE + 1))
else
  red "  $FAIL  .github/workflows/ directory missing"
  yellow "       Fix: mkdir -p $REPO/.github/workflows"
fi

TOTAL=$((TOTAL + 1))
if has_real_ci_workflow; then
  green "  $PASS  CI workflow (test/build/lint)"
  SCORE=$((SCORE + 1))
else
  red "  $FAIL  CI workflow (test/build/lint)"
  # Checked per-pattern: a single ls over both globs fails outright when either one
  # matches nothing, which is the common case (a repo has .yml or .yaml, rarely both).
  if ls "$REPO"/.github/workflows/*.yml >/dev/null 2>&1 \
     || ls "$REPO"/.github/workflows/*.yaml >/dev/null 2>&1; then
    yellow "       Workflows exist, but none runs a build, test, or lint step."
  fi
  yellow "       Fix: Copy a starter from $TPL/.github/workflows/"
fi

echo ""
bold "── README Quality ──"
README_RENDERED="$(rendered_readme)"
TOTAL=$((TOTAL + 1))
if grep -Eqi '!\[[^]]*\]\([^)]+\.(gif|png|jpe?g|webp|svg)([?#][^)]*)?\)|<img[[:space:]][^>]*src[[:space:]]*=' <<<"$README_RENDERED"; then
  green "  $PASS  README references a demo/screenshot"
  SCORE=$((SCORE + 1))
else
  red "  $FAIL  README missing demo GIF or screenshot"
  yellow "       Fix: add an animated GIF above the fold (see references/readme-anatomy.md)"
fi

TOTAL=$((TOTAL + 1))
if grep -qi "quick start\|getting started\|install" "$REPO/README.md" 2>/dev/null; then
  green "  $PASS  README has a Quick Start / install section"
  SCORE=$((SCORE + 1))
else
  red "  $FAIL  README missing Quick Start section"
  yellow "       Fix: add ## Quick Start with a 3-step install"
fi

TOTAL=$((TOTAL + 1))
if grep -Eqi '\[!\[[^]]*\]\([^)]+\)\]\([^)]+\)|!\[[^]]*\]\([^)]*(img\.shields\.io|badge|actions/workflows|contrib\.rocks)[^)]*\)' <<<"$README_RENDERED"; then
  green "  $PASS  README has badges"
  SCORE=$((SCORE + 1))
else
  red "  $FAIL  README missing build/license badges"
  yellow "       Fix: add a badges row at the top (see references/github-metadata.md)"
fi

echo ""
bold "── Optional (situational) ──"
# Grouped, because this list only grows and an ungrouped run of yellow warnings drowns
# the scored output above it. Every line here is unscored: a missing optional file is
# information, not a defect.
echo "  Any repo:"
check_optional ".editorconfig"    ".editorconfig"        "Copy $TPL/.editorconfig (always safe to add)"
check_optional "llms.txt"         "llms.txt"             "Copy $TPL/llms.txt (always safe to add, it indexes the repo for language models)"
check_optional "Dockerfile"       "Dockerfile"           "Add one if this project ships as a container; apply.sh flags a container-build CI job when it sees one"
check_optional "CITATION.cff"     "CITATION.cff"         "Copy $TPL/CITATION.cff if this project is citable (paper/DOI)"
check_optional ".github/FUNDING.yml" ".github/FUNDING.yml" "Copy $TPL/FUNDING.yml if you want sponsorship links"

# The site block is the noisiest part of this section and is irrelevant to most repos, so
# it is printed only where a site is actually detected. Same detector apply.sh uses to
# decide whether to write these files, so the audit and the generator agree.
echo ""
SITE_FRAMEWORK="$(detect_site_framework "$REPO")"
if [ -n "$SITE_FRAMEWORK" ]; then
  echo "  Site files ($SITE_FRAMEWORK detected):"
  check_optional "404.html"     "404.html"     "Copy $TPL/site/404.html"
  check_optional "robots.txt"   "robots.txt"   "Copy $TPL/site/robots.txt; it must point at a sitemap that exists"
  check_optional "sitemap.xml"  "sitemap.xml"  "Copy $TPL/site/sitemap.xml; prefer build-time generation once the site has more than a few pages"
else
  # Still surfaced if they exist, since a leftover robots.txt pointing at a dead sitemap
  # is worth seeing. Just not nagged about when there is no site to serve them.
  SITE_PRESENT=0
  for f in 404.html robots.txt sitemap.xml; do
    [ -e "$REPO/$f" ] && { SITE_PRESENT=1; break; }
  done
  if [ "$SITE_PRESENT" -eq 1 ]; then
    echo "  Site files (no site framework detected, but these exist):"
    check_optional "404.html"    "404.html"    "Remove it, or confirm this repo really does publish a site"
    check_optional "robots.txt"  "robots.txt"  "Remove it, or confirm the sitemap it points at resolves"
    check_optional "sitemap.xml" "sitemap.xml" "Remove it, or confirm this repo really does publish a site"
  else
    echo "  Site files: skipped, no site framework detected (404.html, robots.txt, sitemap.xml)"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PERCENT=$(( (SCORE * 100) / TOTAL ))
if [ "$SCORE" -eq "$TOTAL" ]; then
  green "Score: $SCORE/$TOTAL ($PERCENT%): Enterprise OSS ready ✓"
elif [ "$PERCENT" -ge 70 ]; then
  yellow "Score: $SCORE/$TOTAL ($PERCENT%): Fix the ✗ items above"
else
  red "Score: $SCORE/$TOTAL ($PERCENT%): Significant gaps. Work through the ✗ items."
fi
echo ""
bold "Next step: bash scripts/setup-labels.sh <owner/repo>"
echo ""
