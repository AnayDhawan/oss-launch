#!/usr/bin/env bash
# build-agent-dirs.sh: emits a ready-to-copy skill bundle per agent harness from the
# single SKILL.md + payload, into dist/. Each output dir is self-contained: copy it
# straight into a project (or user config dir) and the skill works.
#
# Formats verified against each project's own docs (not guessed):
#   .claude/skills/<name>/  -- Claude Code: SKILL.md + payload, as-is
#   .codex/skills/<name>/   -- Codex CLI: same SKILL.md format, documented cross-compatible
#   .cursor/rules/<name>.mdc -- Cursor: YAML frontmatter (description, alwaysApply) + body
#   .gemini/extensions/<name>/ -- Gemini CLI: gemini-extension.json + commands/*.toml + GEMINI.md
#   .windsurf/rules/<name>.md -- Windsurf: YAML frontmatter (trigger, description) + body
#   CONVENTIONS.md + .aider.conf.yml -- Aider: a read-on-start conventions file
#
# Usage: bash scripts/build-agent-dirs.sh [output-dir]   (default: dist/)

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist}"
NAME="oss-launch"

# Every adapter that has a description field gets it from SKILL.md's frontmatter rather
# than from a hand-written copy. The copies drifted: Cursor's .mdc was missing trigger
# phrases SKILL.md had picked up since, and Gemini's manifest had no description at all,
# so the extension showed up unlabelled in `gemini extensions list`.
DESCRIPTION="$(sed -nE 's/^description:[[:space:]]*//p' "$ROOT/SKILL.md" | head -1)"
if [ -z "$DESCRIPTION" ]; then
  echo "build-agent-dirs.sh: could not read 'description:' from SKILL.md's frontmatter" >&2
  exit 1
fi

# JSON- and TOML-safe form of the same string (both use double quotes and backslashes).
escape_quotes() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
DESCRIPTION_ESCAPED="$(escape_quotes "$DESCRIPTION")"

# Cursor's .mdc and Windsurf's rule file both carry the description as a YAML plain
# scalar, matching SKILL.md's own frontmatter. A plain scalar cannot contain ": ", so a
# description that grows one would silently produce a rule file the harness misparses.
# Caught here, at build time, rather than in someone's editor.
case "$DESCRIPTION" in
  *": "*)
    echo "build-agent-dirs.sh: SKILL.md's description contains ': ', which breaks the" >&2
    echo "YAML plain scalar used by the Cursor and Windsurf rule files. Reword it." >&2
    exit 1
    ;;
esac

# Released version, for manifests that must declare one (Gemini's extension.json).
# CHANGELOG's newest released heading is the source of truth; fall back to the nearest
# tag, then 0.0.0, never a hardcoded literal that silently goes stale after a release.
VERSION="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$ROOT/CHANGELOG.md" 2>/dev/null | tr -d '#[] ' || true)"
[ -z "$VERSION" ] && VERSION="$(git -C "$ROOT" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)"
[ -z "$VERSION" ] && VERSION="0.0.0"

rm -rf "$OUT"
mkdir -p "$OUT"

# The functional payload every adapter needs: SKILL.md's own instructions plus what
# they reference. Repo-meta files (README, LICENSE, CONTRIBUTING, tests/, demo/, ...)
# describe the oss-launch project itself and aren't needed once installed elsewhere.
copy_payload() {  # copy_payload <dest-dir>
  local dest="$1"
  mkdir -p "$dest"
  cp "$ROOT/SKILL.md" "$dest/"
  cp "$ROOT/AGENTS.md" "$dest/"
  cp -r "$ROOT/references" "$dest/"
  cp -r "$ROOT/templates" "$dest/"
  cp -r "$ROOT/scripts" "$dest/"
}

# --- Claude Code: native format, no adaptation ---
copy_payload "$OUT/.claude/skills/$NAME"

# --- Codex CLI: same SKILL.md format, project-scoped .codex/skills/<name>/ ---
copy_payload "$OUT/.codex/skills/$NAME"

# --- Cursor: .mdc rule (frontmatter + body), self-contained payload alongside it ---
mkdir -p "$OUT/.cursor/rules"
{
  echo "---"
  echo "description: $DESCRIPTION"
  echo "alwaysApply: false"
  echo "---"
  echo ""
  echo "Payload for this rule lives alongside it at \`.cursor/$NAME/\` (SKILL.md, references/,"
  echo "templates/, scripts/). Read \`.cursor/$NAME/SKILL.md\` in full and follow it exactly."
  echo ""
  tail -n +2 "$ROOT/SKILL.md"  # skip SKILL.md's own frontmatter line
} > "$OUT/.cursor/rules/$NAME.mdc"
copy_payload "$OUT/.cursor/$NAME"

# --- Windsurf: .windsurf/rules/<name>.md, same shape as Cursor's .mdc ---
# `trigger: model_decision` is Windsurf's equivalent of alwaysApply:false plus a
# description the model matches against, which is exactly how the Cursor rule behaves.
mkdir -p "$OUT/.windsurf/rules"
{
  echo "---"
  echo "trigger: model_decision"
  echo "description: $DESCRIPTION"
  echo "---"
  echo ""
  echo "Payload for this rule lives alongside it at \`.windsurf/$NAME/\` (SKILL.md, references/,"
  echo "templates/, scripts/). Read \`.windsurf/$NAME/SKILL.md\` in full and follow it exactly."
  echo ""
  tail -n +2 "$ROOT/SKILL.md"
} > "$OUT/.windsurf/rules/$NAME.md"
copy_payload "$OUT/.windsurf/$NAME"

# --- Aider: a conventions file plus the config that loads it on start ---
# Aider has no rules directory and no trigger matching: it reads whatever files the
# config names into every session. So the whole skill body goes into CONVENTIONS.md and
# .aider.conf.yml points at it. Always-on rather than triggered, which is the one real
# behavioural difference from the other four bundles.
AIDER_DIR="$OUT/.aider-bundle"
mkdir -p "$AIDER_DIR"
{
  echo "# $NAME"
  echo ""
  echo "$DESCRIPTION"
  echo ""
  echo "Payload for these conventions lives at \`.aider/$NAME/\` (SKILL.md, references/,"
  echo "templates/, scripts/). Read \`.aider/$NAME/SKILL.md\` in full and follow it exactly"
  echo "when the request matches the triggers above; otherwise ignore this file."
  echo ""
  tail -n +2 "$ROOT/SKILL.md"
} > "$AIDER_DIR/CONVENTIONS.md"
cat > "$AIDER_DIR/.aider.conf.yml" <<YAML
# Loads the $NAME conventions into every session. Aider reads these files on start;
# it has no trigger matching, so the conventions themselves say when they apply.
read:
  - CONVENTIONS.md
YAML
copy_payload "$AIDER_DIR/.aider/$NAME"

# --- Gemini CLI: gemini-extension.json + commands/*.toml + GEMINI.md ---
GEMINI_DIR="$OUT/.gemini/extensions/$NAME"
mkdir -p "$GEMINI_DIR/commands"
cat > "$GEMINI_DIR/gemini-extension.json" <<JSON
{
  "name": "$NAME",
  "version": "$VERSION",
  "description": "$DESCRIPTION_ESCAPED",
  "contextFileName": "GEMINI.md"
}
JSON
cp "$ROOT/AGENTS.md" "$GEMINI_DIR/GEMINI.md"
{
  echo "description = \"$DESCRIPTION_ESCAPED\""
  echo 'prompt = """'
  echo "Read SKILL.md at \`.gemini/extensions/$NAME/SKILL.md\` in full and follow it exactly"
  echo "for this repo. Optional focus or question: {{args}}"
  echo '"""'
} > "$GEMINI_DIR/commands/$NAME.toml"
copy_payload "$GEMINI_DIR"

echo "Built agent dirs under $OUT:"
find "$OUT" -maxdepth 3 -type d | sort
