#!/usr/bin/env bash
# tests/verify-bundles.sh: rebuilds dist/ and proves the bundles are self-contained.
#
# dist/ is gitignored and untracked by design, so nothing but someone running
# build-agent-dirs.sh by hand and eyeballing the output kept it honest (#45). This runs
# the build, then checks each bundle has the payload its harness expects and that its
# scripts still work AFTER being moved somewhere else entirely, which is the actual claim
# a bundle makes: copy this directory into a project and the skill works.
#
# Usage: bash tests/verify-bundles.sh

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0
NAME="oss-launch"

pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; FAILURES=$((FAILURES + 1)); }
assert_file() {  # assert_file <label> <path>
  if [ -f "$2" ]; then pass "$1"; else fail "$1"; fi
}

echo "── build-agent-dirs.sh ──"
if BUILD_OUT="$(bash "$ROOT/scripts/build-agent-dirs.sh" "$TMP/dist" 2>&1)"; then
  pass "build ran clean"
else
  fail "build exited non-zero: $(tail -1 <<<"$BUILD_OUT")"
  echo "$BUILD_OUT"
  exit 1
fi

DIST="$TMP/dist"

# --- every bundle carries the whole payload -------------------------------------------
echo ""
echo "── payload completeness ──"
PAYLOAD_DIRS=(
  ".claude/skills/$NAME"
  ".codex/skills/$NAME"
  ".cursor/$NAME"
  ".windsurf/$NAME"
  ".gemini/extensions/$NAME"
  ".aider-bundle/.aider/$NAME"
)
for rel in "${PAYLOAD_DIRS[@]}"; do
  missing=""
  for item in SKILL.md AGENTS.md references templates scripts; do
    [ -e "$DIST/$rel/$item" ] || missing="$missing $item"
  done
  if [ -z "$missing" ]; then pass "$rel has the full payload"
  else fail "$rel is missing:$missing"; fi
done

# --- per-harness manifests -------------------------------------------------------------
echo ""
echo "── harness manifests ──"

MDC="$DIST/.cursor/rules/$NAME.mdc"
if [ -f "$MDC" ] && head -1 "$MDC" | grep -qx -- "---" && grep -q '^description: .' "$MDC"; then
  pass "Cursor .mdc has frontmatter with a description"
else
  fail "Cursor .mdc missing or has no description in its frontmatter"
fi

WINDSURF="$DIST/.windsurf/rules/$NAME.md"
if [ -f "$WINDSURF" ] && grep -q '^trigger: .' "$WINDSURF" && grep -q '^description: .' "$WINDSURF"; then
  pass "Windsurf rule has trigger + description"
else
  fail "Windsurf rule missing or incomplete"
fi

# The descriptions must be SKILL.md's, not hand-written copies of it (#47).
SKILL_DESC="$(sed -nE 's/^description:[[:space:]]*//p' "$ROOT/SKILL.md" | head -1)"
for f in "$MDC" "$WINDSURF"; do
  if [ -f "$f" ] && grep -Fqx "description: $SKILL_DESC" "$f"; then
    pass "$(basename "$f") description matches SKILL.md verbatim"
  else
    fail "$(basename "$f") description has drifted from SKILL.md"
  fi
done

GEMINI_JSON="$DIST/.gemini/extensions/$NAME/gemini-extension.json"
if [ -f "$GEMINI_JSON" ] && grep -q '"description"' "$GEMINI_JSON"; then
  pass "gemini-extension.json declares a description"
else
  fail "gemini-extension.json missing or has no description (#48)"
fi
if command -v python3 >/dev/null 2>&1; then
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$GEMINI_JSON" 2>/dev/null; then
    pass "gemini-extension.json is valid JSON"
  else
    fail "gemini-extension.json is not valid JSON"
  fi
fi
assert_file "Gemini context file present" "$DIST/.gemini/extensions/$NAME/GEMINI.md"
assert_file "Gemini command file present" "$DIST/.gemini/extensions/$NAME/commands/$NAME.toml"

for f in "$DIST/.aider-bundle/CONVENTIONS.md" "$DIST/.aider-bundle/.aider.conf.yml"; do
  assert_file "Aider $(basename "$f") present" "$f"
done
if grep -q 'CONVENTIONS.md' "$DIST/.aider-bundle/.aider.conf.yml" 2>/dev/null; then
  pass "Aider config reads CONVENTIONS.md"
else
  fail "Aider config does not read CONVENTIONS.md"
fi

# --- self-containment: the scripts must work from somewhere else -----------------------
# Copied out of dist/ into an unrelated directory, so a script that silently resolved a
# path back into this repo fails here instead of in a user's project.
echo ""
echo "── self-containment (bundle relocated) ──"
RELOCATED="$TMP/elsewhere/vendor-drop"
mkdir -p "$RELOCATED"
cp -r "$DIST/.claude/skills/$NAME/." "$RELOCATED/"

TARGET="$TMP/target-repo"
mkdir -p "$TARGET"
printf '# target\n' > "$TARGET/README.md"
printf '{"name":"target","version":"0.1.0"}\n' > "$TARGET/package.json"

if AUDIT_OUT="$(bash "$RELOCATED/scripts/audit.sh" "$TARGET" 2>&1)"; then
  pass "relocated audit.sh ran"
else
  # audit.sh exits 0 even at a low score; a non-zero exit is a real failure.
  fail "relocated audit.sh exited non-zero: $(tail -1 <<<"$AUDIT_OUT")"
fi
if grep -Fq "$RELOCATED/templates" <<<"$AUDIT_OUT"; then
  pass "relocated audit.sh resolves templates inside the bundle"
else
  fail "relocated audit.sh did not point at its own templates dir"
fi
if grep -Fq "$ROOT/templates" <<<"$AUDIT_OUT"; then
  fail "relocated audit.sh reached back into the source repo"
else
  pass "relocated audit.sh never referenced the source repo"
fi

cat > "$TMP/bundle.config" <<'EOF'
AUTHOR="Bundle Test"
SECURITY_EMAIL="bundle@example.com"
TAGLINE="A relocated-bundle target"
OWNER="bundle"
EOF
if APPLY_OUT="$(bash "$RELOCATED/scripts/apply.sh" "$TARGET" --config "$TMP/bundle.config" 2>&1)"; then
  pass "relocated apply.sh scaffolded a repo"
else
  fail "relocated apply.sh exited non-zero: $(tail -1 <<<"$APPLY_OUT")"
fi
for f in LICENSE CONTRIBUTING.md SECURITY.md .github/workflows/ci.yml; do
  assert_file "relocated apply.sh wrote $f" "$TARGET/$f"
done
if LEAKED="$(grep -rl '{{[A-Z_0-9]*}}' "$TARGET" 2>/dev/null)"; then
  fail "relocated apply.sh left unresolved tokens in: $LEAKED"
else
  pass "relocated apply.sh left no unresolved tokens"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All bundle assertions passed."
  exit 0
fi
echo "$FAILURES bundle assertion(s) failed."
exit 1
