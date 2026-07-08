# AGENTS.md

Harness-agnostic entry point for `oss-launch`. If your harness auto-discovers skills the
way Claude Code does (a `SKILL.md` with `description` frontmatter, invoked as a slash
command), install and use it as documented in the README. If your harness has no
skill/slash-command system, this file is your install + invocation path: `SKILL.md` is the
actual workflow definition, everything below just gets you to it on any agent.

## Install per harness

Fastest path for the four harnesses below: clone this repo, run
`bash scripts/build-agent-dirs.sh`, then copy the matching directory out of `dist/`
into your project (or user config dir). Each output dir is self-contained — payload
included, no separate clone needed at runtime.

### Claude Code
```bash
git clone https://github.com/AnayDhawan/oss-launch.git ~/.claude/skills/oss-launch
```
Auto-discovered from `SKILL.md`'s `description` frontmatter. Invoke with `/oss-launch`
inside any repo you want to open source. (Or copy `dist/.claude/skills/oss-launch/`
into a project-scoped `.claude/skills/`.)

### Codex CLI
Codex loads project skills from `.codex/skills/<name>/SKILL.md` — same format as Claude
Code, no adaptation needed. Copy `dist/.codex/skills/oss-launch/` into your project's
`.codex/skills/`, or clone this repo there directly.

### Cursor
Copy `dist/.cursor/rules/oss-launch.mdc` (the rule) and `dist/.cursor/oss-launch/` (its
payload) into your project. Cursor has no slash-command auto-discovery for external
skills; the rule uses `description` + `alwaysApply: false` so the agent pulls it in when
your request matches (open-sourcing a repo), same trigger phrases as `SKILL.md`.

Without the build script: copy `SKILL.md`'s content into a `.cursor/rules/*.mdc` file
yourself, or just say "Read SKILL.md at `<clone path>` and follow it for this repo."

### Gemini CLI
Copy `dist/.gemini/extensions/oss-launch/` into `.gemini/extensions/` (project) or
`~/.gemini/extensions/` (global). It's a real Gemini CLI extension: `gemini-extension.json`
manifest + a `/oss-launch` custom command (`commands/oss-launch.toml`) + `GEMINI.md`
context file, per Gemini CLI's documented extension format.

### Any other agent with shell + file access (Aider, Windsurf, plain chat)
```bash
git clone https://github.com/AnayDhawan/oss-launch.git
```
Then open a session in the target repo and say:

> Read `SKILL.md` from `<clone path>` in full and follow its scan -> report -> ask ->
> generate -> re-audit -> launch flow against this repo.

The workflow has no Claude-specific dependency. It only needs bash execution and file
read/write, which every agent harness provides.

## Running it with no agent at all

```bash
bash scripts/audit.sh .                                   # gap checklist, no agent needed
bash scripts/apply.sh . --config oss-launch.config         # full scaffold, no agent needed
```
`audit.sh` alone tells you what OSS files are missing. `apply.sh` runs the actual
generation step (`SKILL.md` step 3 — filling `templates/` with the repo's real name,
owner, stack, and license) from a config file instead of an agent asking questions — see
`templates/oss-launch.config.example`. It skips README.md (prose generation is genuinely
agent-only) and never overwrites an existing file.

## What any harness needs to run this

- Shell/bash execution, to run `scripts/*.sh`
- File read + write in the target repo
- `git` and `gh` CLI on `PATH`, for remote detection and repo metadata (`references/scan.md`)
- Network access only for the optional launch modules (demo GIF capture via Playwright,
  `gh repo edit` for metadata) — the core scan -> generate flow is fully offline.

## Scope note

`templates/` is the file collection this skill writes into a **user's** repo when
generating an OSS scaffold. The root files (this file, README, LICENSE, `SKILL.md` itself)
describe `oss-launch` the project, not the output it produces. Don't confuse the two when
adapting this AGENTS.md for a harness you're integrating.
