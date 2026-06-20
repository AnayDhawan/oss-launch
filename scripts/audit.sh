#!/usr/bin/env bash
# OSS Audit Script — checks what standard OSS files are missing.
# Usage: bash scripts/audit.sh [REPO_PATH]   (defaults to current directory)
# Resolves its own templates dir, so it runs from a clone or the installed skill.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$ROOT/templates"

REPO="${1:-.}"
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

# pass if ANY of the given paths exist (e.g. .yml or .md variants)
check_any() {
  local label="$1" fix="$2"; shift 2
  local found=0 p
  TOTAL=$((TOTAL + 1))
  for p in "$@"; do
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
  ".github/ISSUE_TEMPLATE/bug_report.yml" ".github/ISSUE_TEMPLATE/bug_report.md"
check_any "Issue template: feature" "Copy $TPL/.github/ISSUE_TEMPLATE/feature_request.yml" \
  ".github/ISSUE_TEMPLATE/feature_request.yml" ".github/ISSUE_TEMPLATE/feature_request.md"
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

check_any "CI workflow (test/build/lint)" "Copy a starter from $TPL/.github/workflows/" \
  ".github/workflows/ci.yml" ".github/workflows/*-ci.yml" ".github/workflows/*.yml"

echo ""
bold "── README Quality ──"
TOTAL=$((TOTAL + 1))
if grep -qi "demo\|screenshot\|gif" "$REPO/README.md" 2>/dev/null; then
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
if grep -q "img.shields.io\|badge\|actions/workflows" "$REPO/README.md" 2>/dev/null; then
  green "  $PASS  README has badges"
  SCORE=$((SCORE + 1))
else
  yellow "  $WARN  README missing build/license badges"
  yellow "       Fix: add a badges row at the top (see references/github-metadata.md)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PERCENT=$(( (SCORE * 100) / TOTAL ))
if [ "$SCORE" -eq "$TOTAL" ]; then
  green "Score: $SCORE/$TOTAL ($PERCENT%) — Enterprise OSS ready ✓"
elif [ "$PERCENT" -ge 70 ]; then
  yellow "Score: $SCORE/$TOTAL ($PERCENT%) — Fix the ✗ items above"
else
  red "Score: $SCORE/$TOTAL ($PERCENT%) — Significant gaps. Work through the ✗ items."
fi
echo ""
bold "Next step: bash scripts/setup-labels.sh <owner/repo>"
echo ""
