#!/usr/bin/env bash
# tests/run.sh — two suites.
#
# 1. audit.sh scoring against three known repo states (empty, partial, fully-scaffolded).
#    Guards against audit-scoring regressions; see #9. These fixtures are built at run
#    time via demo/scaffold.sh rather than committed, so they never drift from what
#    templates/ actually produces.
#
# 2. detect-stack.sh detection against the committed shapes in tests/fixtures/. Those
#    ARE committed, because they encode the input shapes under test; see #16.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$ROOT/tests/fixtures"
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

echo "── audit.sh scoring ──"

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

# --- detection: scripts/lib/detect-stack.sh against tests/fixtures/ --------------------
echo ""
echo "── detect-stack.sh detection ──"

# shellcheck source=scripts/lib/detect-stack.sh
source "$ROOT/scripts/lib/detect-stack.sh"

assert_detect() {  # assert_detect <label> <function> <fixture-dir> <expected>
  local label="$1" fn="$2" dir="$3" expected="$4" actual
  actual="$("$fn" "$dir")"
  if [ "$actual" = "$expected" ]; then
    echo "  PASS  $label: $fn -> '${actual:-<empty>}'"
  else
    echo "  FAIL  $label: $fn expected '${expected:-<empty>}', got '${actual:-<empty>}'"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_detect "kotlin project"      detect_stack    "$FIXTURES/kotlin-project"      "kotlin"
assert_detect "scala project"       detect_stack    "$FIXTURES/scala-project"       "scala"
# Regression guard for the kotlin branch: plain Gradle with no Kotlin evidence must
# still resolve to java, or every Gradle repo gets misclassified.
assert_detect "gradle-java project" detect_stack    "$FIXTURES/gradle-java-project" "java"

# Orthogonal axes: the primary stack must be unchanged by either.
assert_detect "pnpm monorepo"       detect_monorepo "$FIXTURES/pnpm-monorepo"       "pnpm"
assert_detect "pnpm monorepo stack" detect_stack    "$FIXTURES/pnpm-monorepo"       "node"
assert_detect "dockerized node"     detect_docker   "$FIXTURES/dockerized-node"     "true"
assert_detect "dockerized node stack" detect_stack  "$FIXTURES/dockerized-node"     "node"
# Negative cases: neither axis may fire on a plain single-package repo.
assert_detect "no monorepo"         detect_monorepo "$FIXTURES/dockerized-node"     ""
assert_detect "no docker"           detect_docker   "$FIXTURES/pnpm-monorepo"       ""

# --- per-stack lookups resolve to files that actually exist ----------------------------
echo ""
echo "── per-stack template lookups ──"

for stack in node python rust go php dotnet ruby java swift kotlin scala generic; do
  for fn in stack_gitignore_file stack_ci_file; do
    rel="$("$fn" "$stack")"
    if [ -f "$ROOT/templates/$rel" ]; then
      echo "  PASS  $stack $fn -> $rel"
    else
      echo "  FAIL  $stack $fn -> $rel (missing under templates/)"
      FAILURES=$((FAILURES + 1))
    fi
  done
done

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All assertions passed."
  exit 0
else
  echo "$FAILURES assertion(s) failed."
  exit 1
fi
