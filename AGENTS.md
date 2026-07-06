# AGENTS.md

Harness-agnostic entry point for `oss-launch`. If your harness auto-discovers skills the
way Claude Code does (a `SKILL.md` with `description` frontmatter, invoked as a slash
command), install and use it as documented in the README. If your harness has no
skill/slash-command system, this file is your install + invocation path: `SKILL.md` is the
actual workflow definition, everything below just gets you to it on any agent.

## Install per harness

### Claude Code
```bash
git clone https://github.com/AnayDhawan/oss-launch.git ~/.claude/skills/oss-launch
```
Auto-discovered from `SKILL.md`'s `description` frontmatter. Invoke with `/oss-launch`
inside any repo you want to open source.

### Cursor
Clone the repo anywhere, then either:
- Copy `SKILL.md`'s content into a Cursor rule at `.cursor/rules/oss-launch.mdc`, or
- Point the agent at it directly: "Read SKILL.md at `<clone path>` and follow it for this repo."

Cursor has no slash-command auto-discovery for external skills; a rule (or a direct
pointer, as above) is the closest equivalent.

### Any other agent with shell + file access (Aider, Codex CLI, Windsurf, plain chat)
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
bash scripts/audit.sh .        # gap checklist against the current repo, no agent needed
```
`audit.sh` alone tells you what OSS files are missing. The adapted-generation step
(`SKILL.md` step 3 — filling `templates/` placeholders with the repo's real name, owner,
stack, and license) is what an agent adds on top of the raw checklist.

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
