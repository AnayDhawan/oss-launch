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

# The denominator is read out of audit.sh's own output, never hardcoded. Baking "/16" into
# the sed made every assertion here fail with a confusing "got /16" the moment a new
# scored check was added to audit.sh, because the pattern stopped matching and returned
# empty. Parsed, a new check produces one clear failure per fixture with a real number.
score_line_of() {  # score_line_of <dir> -> "<score>/<total>", or empty when unparseable
  bash "$ROOT/scripts/audit.sh" "$1" 2>&1 \
    | sed -n 's#.*Score: \([0-9]\{1,\}\)/\([0-9]\{1,\}\).*#\1/\2#p' | head -1
}

MAX_SCORE=""  # audit.sh's current denominator, resolved once from a real run below

assert_score() {  # assert_score <label> <dir> <expected>
  local label="$1" dir="$2" expected="$3" line actual total
  line="$(score_line_of "$dir")"
  if [ -z "$line" ]; then
    echo "  FAIL  $label: could not parse a 'Score: N/M' line out of audit.sh's output"
    FAILURES=$((FAILURES + 1))
    return
  fi
  actual="${line%%/*}"
  total="${line##*/}"

  # Every fixture must be scored against the same denominator; a mismatch means audit.sh
  # produced different totals for different repo shapes, which the expectations here
  # (absolute scores) quietly assume cannot happen.
  if [ -z "$MAX_SCORE" ]; then
    MAX_SCORE="$total"
  elif [ "$total" != "$MAX_SCORE" ]; then
    echo "  FAIL  $label: denominator changed between fixtures ($MAX_SCORE then $total)"
    FAILURES=$((FAILURES + 1))
    return
  fi

  if [ "$actual" = "$expected" ]; then
    echo "  PASS  $label: $actual/$total"
  else
    echo "  FAIL  $label: expected $expected/$total, got $actual/$total"
    FAILURES=$((FAILURES + 1))
  fi
}

# The fully-scaffolded fixtures are asserted as "everything audit.sh scores", not as a
# literal 16, so adding a scored check that apply.sh already satisfies does not need a
# test edit; adding one it does NOT satisfy still fails, which is the point.
assert_full_score() {  # assert_full_score <label> <dir>
  local label="$1" dir="$2" line
  line="$(score_line_of "$dir")"
  if [ -z "$line" ]; then
    echo "  FAIL  $label: could not parse a 'Score: N/M' line out of audit.sh's output"
    FAILURES=$((FAILURES + 1))
    return
  fi
  assert_score "$label" "$dir" "${line##*/}"
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

# --- CI check must judge what a workflow DOES, not that a .yml exists (#49) ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/triage-only" >/dev/null
mkdir -p "$TMP/triage-only/.github/workflows"
cat > "$TMP/triage-only/.github/workflows/stale.yml" <<'EOF'
name: Stale
on:
  schedule:
    - cron: "0 3 * * *"
jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          days-before-stale: 90
EOF
assert_audit_line "triage-only workflow does not count as CI (#49)" "$TMP/triage-only" \
  "$FAIL_SYMBOL  CI workflow (test/build/lint)"
assert_audit_line "and says why, rather than just failing" "$TMP/triage-only" \
  "none runs a build, test, or lint step"

# The same repo with one workflow that actually runs a test command does score it.
bash "$ROOT/demo/scaffold.sh" init "$TMP/real-ci" >/dev/null
mkdir -p "$TMP/real-ci/.github/workflows"
cat > "$TMP/real-ci/.github/workflows/verify.yml" <<'EOF'
name: Verify
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: |
          npm ci
          npm test
EOF
assert_audit_line "a workflow with a real test step counts as CI (#49)" "$TMP/real-ci" \
  "$PASS_SYMBOL  CI workflow (test/build/lint)"

# --- Optional section: the site block is suppressed where there is no site (#51) ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/no-site" >/dev/null
assert_audit_line "site files are skipped for a repo with no site (#51)" "$TMP/no-site" \
  "Site files: skipped, no site framework detected"

# --- full: complete scaffold ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/full" >/dev/null
bash "$ROOT/demo/scaffold.sh" apply "$TMP/full" >/dev/null
assert_full_score "full fixture" "$TMP/full"

# --- full, feature template under a project-specific name (e.g. Components'
#     new_component.yml). Regression guard for #31: check_any must not hardcode
#     feature_request.{yml,md} and miss an equivalent template under another name. ---
bash "$ROOT/demo/scaffold.sh" init "$TMP/full-renamed" >/dev/null
bash "$ROOT/demo/scaffold.sh" apply "$TMP/full-renamed" >/dev/null
mv "$TMP/full-renamed/.github/ISSUE_TEMPLATE/feature_request.yml" \
   "$TMP/full-renamed/.github/ISSUE_TEMPLATE/new_component.yml"
assert_full_score "full fixture, renamed feature template (#31)" "$TMP/full-renamed"

# --- release.sh prunes empty CHANGELOG categories (#36) --------------------------------
echo ""
echo "── release.sh CHANGELOG pruning ──"

# release.sh is interactive end to end (three confirm prompts, a git commit, a tag push),
# so the pruning pass is exercised directly rather than by driving the whole script.
PRUNE_AWK="$(sed -n "/^  awk -v version=/,/^  ' CHANGELOG.md > CHANGELOG.md.pruned/p" "$ROOT/scripts/release.sh" \
  | sed -e "1s/^  awk -v version=\"\$NEW_VERSION\" '//" -e "\$d")"

prune_changelog() {  # prune_changelog <version> <file>
  awk -v version="$1" "$PRUNE_AWK" "$2"
}

CHANGELOG_FIXTURE="$TMP/CHANGELOG.md"
cat > "$CHANGELOG_FIXTURE" <<'EOF'
# Changelog

## [Unreleased]

### Added

### Changed

### Fixed

---

## [2.0.0] - 2026-09-03

### Added

### Changed
- A real change.

### Deprecated

### Removed

### Fixed

### Security

---

## [1.0.0] - 2026-01-01

### Added
- First release.
EOF

PRUNED="$(prune_changelog "2.0.0" "$CHANGELOG_FIXTURE")"

assert_pruned() {  # assert_pruned <label> <test> <pattern>
  local label="$1" mode="$2" pattern="$3"
  if [ "$mode" = "absent" ]; then
    if grep -Fq -- "$pattern" <<<"$PRUNED"; then
      echo "  FAIL  $label"
      FAILURES=$((FAILURES + 1))
    else
      echo "  PASS  $label"
    fi
  else
    if grep -Fq -- "$pattern" <<<"$PRUNED"; then
      echo "  PASS  $label"
    else
      echo "  FAIL  $label"
      FAILURES=$((FAILURES + 1))
    fi
  fi
}

# The released section keeps only the category that had content.
RELEASED_SECTION="$(awk '/^## \[2\.0\.0\]/{f=1;next} /^## \[/{f=0} f' <<<"$PRUNED")"
if [ "$(grep -c '^### ' <<<"$RELEASED_SECTION")" = "1" ]; then
  echo "  PASS  released section keeps only its non-empty category"
else
  echo "  FAIL  released section has $(grep -c '^### ' <<<"$RELEASED_SECTION") category headings, expected 1"
  FAILURES=$((FAILURES + 1))
fi
assert_pruned "released section keeps the real entry" present "- A real change."

# [Unreleased] must keep its empty categories: they are the menu for the next entry.
UNRELEASED_SECTION="$(awk '/^## \[Unreleased\]/{f=1;next} /^## \[/{f=0} f' <<<"$PRUNED")"
if [ "$(grep -c '^### ' <<<"$UNRELEASED_SECTION")" = "3" ]; then
  echo "  PASS  [Unreleased] keeps its empty categories"
else
  echo "  FAIL  [Unreleased] has $(grep -c '^### ' <<<"$UNRELEASED_SECTION") category headings, expected 3"
  FAILURES=$((FAILURES + 1))
fi

# Older sections and the section separators are untouched.
assert_pruned "older releases are untouched" present "- First release."
if [ "$(grep -c '^---$' <<<"$PRUNED")" = "$(grep -c '^---$' "$CHANGELOG_FIXTURE")" ]; then
  echo "  PASS  section separators are preserved"
else
  echo "  FAIL  section separator count changed"
  FAILURES=$((FAILURES + 1))
fi

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

# npm vs yarn workspaces (#39). Both spell it "workspaces" in package.json, so the
# flavour comes from "packageManager" first. The npm fixture deliberately carries a stale
# yarn.lock: a lone lockfile sniff reported yarn for a repo that had migrated to npm.
assert_detect "npm workspaces"        detect_monorepo "$FIXTURES/npm-workspaces"   "npm"
assert_detect "npm workspaces stack"  detect_stack    "$FIXTURES/npm-workspaces"   "node"
assert_detect "yarn workspaces"       detect_monorepo "$FIXTURES/yarn-workspaces"  "yarn"

# --- site detection: scripts/lib/detect-site.sh ----------------------------------------
echo ""
echo "── detect-site.sh detection ──"

# shellcheck source=scripts/lib/detect-site.sh
source "$ROOT/scripts/lib/detect-site.sh"

assert_detect "hugo site"     detect_site_framework "$FIXTURES/hugo-site"     "hugo"
assert_detect "eleventy site" detect_site_framework "$FIXTURES/eleventy-site" "eleventy"
# The conservative rule this detector is built on: config.toml is a generic filename, so
# it must never trigger Hugo on its own without a corroborating Hugo-only directory.
assert_detect "bare config.toml is not a site" detect_site_framework "$FIXTURES/toml-config-only" ""
assert_detect "plain node repo is not a site"  detect_site_framework "$FIXTURES/dockerized-node"  ""

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
