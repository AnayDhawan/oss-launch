#!/usr/bin/env bash
# build-agent-dirs.sh — emits a ready-to-copy skill bundle per agent harness from the
# single SKILL.md + payload, into dist/. Each output dir is self-contained: copy it
# straight into a project (or user config dir) and the skill works.
#
# Formats verified against each project's own docs (not guessed):
#   .claude/skills/<name>/  -- Claude Code: SKILL.md + payload, as-is
#   .codex/skills/<name>/   -- Codex CLI: same SKILL.md format, documented cross-compatible
#   .cursor/rules/<name>.mdc -- Cursor: YAML frontmatter (description, alwaysApply) + body
#   .gemini/extensions/<name>/ -- Gemini CLI: gemini-extension.json + commands/*.toml + GEMINI.md
#
# Usage: bash scripts/build-agent-dirs.sh [output-dir]   (default: dist/)

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist}"
NAME="oss-launch"

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
  echo "description: Scan a repo and generate a tailored open-source file collection (README, LICENSE, CONTRIBUTING, CI, launch playbook). Trigger on \"open source this\", \"OSS checklist\", \"prep for launch\", \"add a license/security policy\"."
  echo "alwaysApply: false"
  echo "---"
  echo ""
  echo "Payload for this rule lives alongside it at \`.cursor/$NAME/\` (SKILL.md, references/,"
  echo "templates/, scripts/). Read \`.cursor/$NAME/SKILL.md\` in full and follow it exactly."
  echo ""
  tail -n +2 "$ROOT/SKILL.md"  # skip SKILL.md's own frontmatter line
} > "$OUT/.cursor/rules/$NAME.mdc"
copy_payload "$OUT/.cursor/$NAME"

# --- Gemini CLI: gemini-extension.json + commands/*.toml + GEMINI.md ---
GEMINI_DIR="$OUT/.gemini/extensions/$NAME"
mkdir -p "$GEMINI_DIR/commands"
cat > "$GEMINI_DIR/gemini-extension.json" <<JSON
{
  "name": "$NAME",
  "version": "1.0.0",
  "contextFileName": "GEMINI.md"
}
JSON
cp "$ROOT/AGENTS.md" "$GEMINI_DIR/GEMINI.md"
{
  echo "description = \"Scan a repo and generate a tailored open-source file collection.\""
  echo 'prompt = """'
  echo "Read SKILL.md at \`.gemini/extensions/$NAME/SKILL.md\` in full and follow it exactly"
  echo "for this repo. Optional focus or question: {{args}}"
  echo '"""'
} > "$GEMINI_DIR/commands/$NAME.toml"
copy_payload "$GEMINI_DIR"

echo "Built agent dirs under $OUT:"
find "$OUT" -maxdepth 3 -type d | sort
