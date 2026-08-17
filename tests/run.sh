#!/usr/bin/env bash
# tests/run.sh: two suites.
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
PASS_SYMBOL="✓"
FAIL_SYMBOL="✗"

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

assert_audit_line() {  # assert_audit_line <label> <dir> <expected text>
  local label="$1" dir="$2" expected="$3" output
  output="$(bash "$ROOT/scripts/audit.sh" "$dir" 2>&1)"
  if grep -Fq "$expected" <<<"$output"; then
    echo "  PASS  $label"
  else
    echo "  FAIL  $label: missing '$expected'"
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

# --- README media: comments and fenced examples are not rendered content ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/non-rendered-media" >/dev/null
cat > "$TMP/non-rendered-media/README.md" <<'EOF'
# Project

<!-- A demo GIF is still TODO.
![Demo](docs/media/demo.gif)
-->

```markdown
![Screenshot](docs/media/screenshot.png)
[![CI](https://img.shields.io/badge/build-passing.svg)](https://example.com)
```
EOF
assert_audit_line "HTML comments/fences do not count as media" "$TMP/non-rendered-media" \
  "$FAIL_SYMBOL  README missing demo GIF or screenshot"
assert_audit_line "scored badge failure uses the failure marker" "$TMP/non-rendered-media" \
  "$FAIL_SYMBOL  README missing build/license badges"

# --- README media: rendered image and provider-agnostic linked badge shapes ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/rendered-image" >/dev/null
cat > "$TMP/rendered-image/README.md" <<'EOF'
# Project

![Walkthrough](docs/media/walkthrough.gif)
EOF
assert_audit_line "rendered Markdown image counts" "$TMP/rendered-image" \
  "$PASS_SYMBOL  README references a demo/screenshot"

bash "$ROOT/demo/scaffold.sh" init "$TMP/rendered-html-image" >/dev/null
cat > "$TMP/rendered-html-image/README.md" <<'EOF'
# Project

<img src="docs/media/walkthrough.webp" alt="Product walkthrough">
EOF
assert_audit_line "rendered HTML image counts" "$TMP/rendered-html-image" \
  "$PASS_SYMBOL  README references a demo/screenshot"

bash "$ROOT/demo/scaffold.sh" init "$TMP/linked-badge" >/dev/null
cat > "$TMP/linked-badge/README.md" <<'EOF'
# Project

[![Contributors](https://contrib.rocks/image?repo=example/project)](https://github.com/example/project/graphs/contributors)
EOF
assert_audit_line "provider-agnostic linked image counts as badge" "$TMP/linked-badge" \
  "$PASS_SYMBOL  README has badges"

# --- full: complete scaffold ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/full" >/dev/null
bash "$ROOT/demo/scaffold.sh" apply "$TMP/full" >/dev/null
assert_score "full fixture" "$TMP/full" 16

# --- full, feature template under a project-specific name (e.g. Components'
#     new_component.yml). Regression guard for #31: check_any must not hardcode
#     feature_request.{yml,md} and miss an equivalent template under another name. ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/full-renamed" >/dev/null
bash "$ROOT/demo/scaffold.sh" apply "$TMP/full-renamed" >/dev/null
mv "$TMP/full-renamed/.github/ISSUE_TEMPLATE/feature_request.yml" \
   "$TMP/full-renamed/.github/ISSUE_TEMPLATE/new_component.yml"
assert_score "full fixture, renamed feature template (#31)" "$TMP/full-renamed" 16

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
echo "── apply.sh per-stack smoke test ──"

# Regression guard for the class of bug a real, shipped-since-v1.0.0 crash belonged to (a
# crash on every Go repo, since fixed): demo/scaffold.sh's fixture is node-only, so no
# fixture had ever run apply.sh's fill()/command tables against any other stack. This
# drives apply.sh once per detected stack against a bare marker file; a stack-specific
# crash now shows up here instead of in a user's terminal.
SMOKE_CONFIG="$TMP/smoke.oss-launch.config"
cat > "$SMOKE_CONFIG" <<'EOF'
AUTHOR="Smoke Test"
SECURITY_EMAIL="smoke@example.com"
TAGLINE="A smoke-tested project"
OWNER="smoke"
EOF

smoke_stack() {  # smoke_stack <stack> <marker-file-relative-path-or-empty> [marker-content]
  local stack="$1" marker="$2" content="${3:-}" dir err
  dir="$TMP/smoke-$stack"
  mkdir -p "$dir"
  if [ -n "$marker" ]; then
    mkdir -p "$dir/$(dirname "$marker")"
    printf '%s' "$content" > "$dir/$marker"
  fi
  printf '# smoke\n' > "$dir/README.md"
  if err="$(bash "$ROOT/scripts/apply.sh" "$dir" --config "$SMOKE_CONFIG" 2>&1 >/dev/null)"; then
    echo "  PASS  $stack: apply.sh ran clean"
  else
    echo "  FAIL  $stack: apply.sh exited non-zero -- $(tail -1 <<<"$err")"
    FAILURES=$((FAILURES + 1))
  fi
}

smoke_stack node    package.json     '{"name":"smoke","version":"0.1.0"}'
smoke_stack python  pyproject.toml   $'[project]\nname = "smoke"\nversion = "0.1.0"'
smoke_stack rust    Cargo.toml       $'[package]\nname = "smoke"\nversion = "0.1.0"'
smoke_stack go      go.mod           'module smoke'
smoke_stack php     composer.json    '{"name":"smoke/smoke"}'
smoke_stack dotnet  smoke.csproj     '<Project Sdk="Microsoft.NET.Sdk"></Project>'
smoke_stack ruby    Gemfile          'source "https://rubygems.org"'
smoke_stack java    pom.xml          '<project></project>'
smoke_stack swift   Package.swift    '// swift-tools-version:5.9'
smoke_stack kotlin  build.gradle.kts 'plugins { kotlin("jvm") version "1.9.0" }'
smoke_stack scala   build.sbt        'name := "smoke"'
smoke_stack generic ""               ""

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All assertions passed."
  exit 0
else
  echo "$FAILURES assertion(s) failed."
  exit 1
fi
