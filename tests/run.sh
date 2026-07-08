#!/usr/bin/env bash
# tests/run.sh — asserts scripts/audit.sh's score against three known fixture states
# (empty, partial, fully-scaffolded). Guards against audit-scoring regressions; see #9.
# Fixtures are built at run time via demo/scaffold.sh rather than committed, so they
# never drift from what templates/ actually produces.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

score_of() {  # score_of <dir> -> numeric score out of 16
  bash "$ROOT/scripts/audit.sh" "$1" 2>&1 | sed -n 's/.*Score: \([0-9]\+\)\/16.*/\1/p'
}

assert_score() {  # assert_score <label> <dir> <expected>
  local label="$1" dir="$2" expected="$3" actual
  actual="$(score_of "$dir")"
  if [ "$actual" = "$expected" ]; then
    echo "  PASS  $label: $actual/16"
  else
    echo "  FAIL  $label: expected $expected/16, got $actual/16"
    FAILURES=$((FAILURES + 1))
  fi
}

# --- empty: bare fixture, README only ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/empty" >/dev/null
assert_score "empty fixture" "$TMP/empty" 1

# --- partial: README + LICENSE only ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/partial" >/dev/null
cp "$ROOT/templates/LICENSE-apache.txt" "$TMP/partial/LICENSE"
assert_score "partial fixture" "$TMP/partial" 2

# --- full: complete scaffold ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/full" >/dev/null
bash "$ROOT/demo/scaffold.sh" apply "$TMP/full" >/dev/null
assert_score "full fixture" "$TMP/full" 16

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All audit.sh scoring assertions passed."
  exit 0
else
  echo "$FAILURES assertion(s) failed."
  exit 1
fi
