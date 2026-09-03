#!/usr/bin/env bash
# check-action-pins.sh: staleness watch for the GitHub Actions pinned inside
# templates/.github/workflows/*.yml.
#
# Those templates are the payload copied into a USER's repo. A stale pin there is worse
# than a stale pin here: it hands every freshly scaffolded project an immediate
# dependabot PR, which is a bad first impression from a tool whose whole pitch is
# "your repo is set up correctly". This script is the watch that catches it.
#
# It reads every `uses: <owner>/<repo>@<ref>` line across the workflow templates,
# resolves each unique action's newest release (falling back to tags when a repo cuts
# no releases), and reports any pin whose major version has fallen behind.
#
# Major-only is the right default: a `@vN` shorthand pin is a moving target that picks up
# minors and patches on its own, so reporting it as behind would be noise. --strict adds a
# full-version comparison for pins that are NOT a bare major (`@v2.1`, `@v2.37.2`), which
# pin precisely and therefore do go stale without anyone noticing.
#
# Usage:
#   bash scripts/check-action-pins.sh                # human-readable report to stdout
#   bash scripts/check-action-pins.sh --report FILE  # also write a markdown report
#   bash scripts/check-action-pins.sh --strict       # also flag minor/patch drift
#
# Exit codes: 0 = all pins current, 1 = drift found, 2 = usage/dependency error.
# Requires: gh CLI, authenticated (the workflow supplies GITHUB_TOKEN).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_GLOB="$ROOT/templates/.github/workflows"
REPORT=""
STRICT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --report) REPORT="${2:-}"; shift 2 ;;
    --strict) STRICT=1; shift ;;
    -h|--help) sed -n '2,26p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "check-action-pins.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "check-action-pins.sh: gh CLI not found. Install from https://cli.github.com" >&2
  exit 2
fi
if [ ! -d "$WORKFLOW_GLOB" ]; then
  echo "check-action-pins.sh: no workflow templates at $WORKFLOW_GLOB" >&2
  exit 2
fi

# --- collect every pin: "<action>@<ref>|<template basename>" ---------------------------
# Only owner/repo@ref forms. Skips local (./…) and docker:// actions, which have no
# upstream release feed to compare against.
PINS="$(
  grep -rhoE '^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*[A-Za-z0-9._-]+/[A-Za-z0-9._/-]+@[A-Za-z0-9._-]+' \
    "$WORKFLOW_GLOB"/*.yml 2>/dev/null \
    | sed -E 's/.*uses:[[:space:]]*//' \
    | sort -u
)"

if [ -z "$PINS" ]; then
  echo "No pinned actions found in $WORKFLOW_GLOB. Nothing to check."
  exit 0
fi

# where each action is pinned, for the report
locations_for() {  # locations_for <action@ref>
  grep -rlF "$1" "$WORKFLOW_GLOB"/*.yml 2>/dev/null \
    | while read -r f; do basename "$f"; done | sort -u | paste -sd', ' -
}

# --- resolve the newest upstream ref for one action ------------------------------------
latest_ref() {  # latest_ref <owner/repo> -> prints newest release tag, or newest tag
  local action_repo="$1" tag=""
  tag="$(gh api "repos/$action_repo/releases/latest" --jq '.tag_name' 2>/dev/null || true)"
  if [ -z "$tag" ] || [ "$tag" = "null" ]; then
    # Repos that never cut releases (ruby/setup-ruby historically) still tag.
    tag="$(gh api "repos/$action_repo/tags?per_page=100" \
             --jq '[.[].name | select(test("^v?[0-9]+\\.[0-9]+"))] | .[0] // empty' 2>/dev/null || true)"
  fi
  printf '%s' "$tag"
}

major_of() {  # major_of <ref> -> leading integer, or empty when the ref isn't semver-ish
  printf '%s' "$1" | sed -nE 's/^v?([0-9]+).*/\1/p'
}

is_bare_major() {  # is_bare_major <ref> -> true for "v3"/"3", false for "v3.1"/"3.1.2"
  printf '%s' "$1" | grep -qE '^v?[0-9]+$'
}

version_lt() {  # version_lt <a> <b> -> 0 when a sorts strictly before b
  local a="${1#v}" b="${2#v}"
  [ "$a" = "$b" ] && return 1
  [ "$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -1)" = "$a" ]
}

# --- compare ---------------------------------------------------------------------------
STALE=0
CHECKED=0
UNRESOLVED=0
ROWS=""
NOTES=""

while IFS= read -r pin; do
  [ -z "$pin" ] && continue
  action="${pin%@*}"
  ref="${pin##*@}"
  CHECKED=$((CHECKED + 1))

  latest="$(latest_ref "$action")"
  if [ -z "$latest" ]; then
    UNRESOLVED=$((UNRESOLVED + 1))
    NOTES="${NOTES}- \`$action\`: could not resolve a release or tag upstream (renamed, deleted, or rate-limited). Pinned at \`$ref\`.
"
    echo "  ?  $action@$ref  (upstream ref unresolved)"
    continue
  fi

  pinned_major="$(major_of "$ref")"
  latest_major="$(major_of "$latest")"

  if [ -z "$pinned_major" ]; then
    # SHA pin or a moving branch name: no major to compare. Report, don't fail.
    NOTES="${NOTES}- \`$action\` is pinned to \`$ref\`, which is not a version ref (SHA or branch). Newest upstream is \`$latest\`; verify by hand.
"
    echo "  -  $action@$ref  (not a version ref; newest upstream $latest)"
    continue
  fi

  if [ -n "$latest_major" ] && [ "$latest_major" -gt "$pinned_major" ] 2>/dev/null; then
    STALE=$((STALE + 1))
    ROWS="${ROWS}| \`$action\` | \`$ref\` | \`$latest\` | $(locations_for "$pin") |
"
    echo "  x  $action@$ref  ->  $latest  STALE"
  elif [ "$STRICT" -eq 1 ] && ! is_bare_major "$ref" && version_lt "$ref" "$latest"; then
    # A precise pin (v2.1, v2.37.2) does not float, so it is genuinely behind. A bare
    # `@vN` is skipped here on purpose: it already tracks minors and patches itself.
    STALE=$((STALE + 1))
    ROWS="${ROWS}| \`$action\` | \`$ref\` | \`$latest\` | $(locations_for "$pin") |
"
    echo "  x  $action@$ref  ->  $latest  STALE (minor/patch, --strict)"
  else
    echo "  ok $action@$ref  (newest upstream $latest)"
  fi
done <<< "$PINS"

echo ""
echo "Checked $CHECKED pinned action(s): $STALE stale, $UNRESOLVED unresolved."

# --- markdown report -------------------------------------------------------------------
if [ -n "$REPORT" ]; then
  {
    if [ "$STALE" -gt 0 ]; then
      if [ "$STRICT" -eq 1 ]; then
        echo "\`templates/.github/workflows/\` pins **$STALE action(s)** that have fallen behind upstream (\`--strict\`: precise pins are compared on the full version, bare \`@vN\` pins on the major only)."
      else
        echo "\`templates/.github/workflows/\` pins **$STALE action(s)** that have shipped a newer major version upstream."
      fi
      echo ""
      echo "Every repo scaffolded by \`apply.sh\` inherits these pins, so a stale one here becomes an immediate dependabot PR in someone else's brand-new project."
      echo ""
      echo "| Action | Pinned | Latest upstream | Templates |"
      echo "|---|---|---|---|"
      printf '%s' "$ROWS"
      echo ""
      echo "Bump each pin in the listed templates, then re-run \`bash scripts/check-action-pins.sh\` to confirm."
    else
      echo "All $CHECKED pinned action(s) in \`templates/.github/workflows/\` are on the newest major version upstream."
    fi
    if [ -n "$NOTES" ]; then
      echo ""
      echo "**Needs a human look:**"
      echo ""
      printf '%s' "$NOTES"
    fi
  } > "$REPORT"
  echo "Report written to $REPORT"
fi

# GitHub Actions output, for the workflow's conditional issue handling
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "stale=$STALE" >> "$GITHUB_OUTPUT"
  echo "checked=$CHECKED" >> "$GITHUB_OUTPUT"
fi

[ "$STALE" -gt 0 ] && exit 1
exit 0
