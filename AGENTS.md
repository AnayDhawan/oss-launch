# AGENTS.md

Harness-agnostic entry point for `oss-launch`. If your harness auto-discovers skills the
way Claude Code does (a `SKILL.md` with `description` frontmatter, invoked as a slash
command), install and use it as documented in the README. If your harness has no
skill/slash-command system, this file is your install + invocation path: `SKILL.md` is the
actual workflow definition, everything below just gets you to it on any agent.

## Install per harness

Fastest path for the six harnesses below: clone this repo, run
`bash scripts/build-agent-dirs.sh`, then copy the matching directory out of `dist/`
into your project (or user config dir). Each output dir is self-contained: payload
included, no separate clone needed at runtime.

**Verification status, so you know what you're getting:** Claude Code is the harness this
skill is developed and dogfooded on daily. Every other bundle is built to that platform's
documented extension format, structurally checked in CI by `tests/verify-bundles.sh`, and
verified self-contained (every path its `SKILL.md` names resolves inside the bundle, and
the bundled scripts run from where they land, after being relocated). None of them has been
**live-trigger-tested** inside a real install: nobody has yet typed "open source this
repo" into one and watched the agent pull the bundle in on its own.

The reasons differ, and they are not equally fixable:

| Harness | Bundle | Live-trigger-tested | Why not |
|---|---|---|---|
| Claude Code | `.claude/skills/` | yes, dogfooded daily | - |
| Codex CLI | `.codex/skills/` | no | needs an authenticated OpenAI account |
| Gemini CLI | `.gemini/extensions/` | no | needs an authenticated Google account |
| Cursor | `.cursor/rules/` | **not planned** | Cursor's CLI is an editor launcher with no headless/agent subcommand, so there is no way to drive it non-interactively from a shell. Format-verified, chat-pane only |
| Windsurf | `.windsurf/rules/` | no | same rule-file shape as Cursor's; not yet verified against a real Windsurf install |
| Aider | `CONVENTIONS.md` | no | always-on conventions file, not a triggered rule; see the Aider section below |

Cursor is a deliberate scope decision, not a backlog item: it stays format-verified and
chat-pane-only unless Cursor ships a shell-drivable agent mode. If any bundle misbehaves,
that's a bug worth reporting; `tests/agent-bundle-verification.md` records exactly what has
and hasn't been checked, and why. The "any other agent" path below works everywhere
regardless, since it needs nothing but a shell and a file read.

### Claude Code
```bash
git clone https://github.com/AnayDhawan/oss-launch.git ~/.claude/skills/oss-launch
```
Auto-discovered from `SKILL.md`'s `description` frontmatter. Invoke with `/oss-launch`
inside any repo you want to open source. (Or copy `dist/.claude/skills/oss-launch/`
into a project-scoped `.claude/skills/`.)

### Codex CLI
*(installed and format-verified 2026-08-31; not live-tested - blocked on an authenticated
OpenAI account, not a capability gap; see `tests/agent-bundle-verification.md`)*

Codex loads project skills from `.codex/skills/<name>/SKILL.md`: same format as Claude
Code, no adaptation needed. Copy `dist/.codex/skills/oss-launch/` into your project's
`.codex/skills/`, or clone this repo there directly.

### Cursor
*(format-verified, chat-pane only. Live-trigger-testing is not planned: Cursor's CLI has
no headless/agent subcommand to drive it from. See verification status above.)*

Copy `dist/.cursor/rules/oss-launch.mdc` (the rule) and `dist/.cursor/oss-launch/` (its
payload) into your project. Cursor has no slash-command auto-discovery for external
skills; the rule uses `description` + `alwaysApply: false` so the agent pulls it in when
your request matches (open-sourcing a repo). The `description` is copied verbatim from
`SKILL.md`'s frontmatter at build time, so the trigger phrases cannot drift apart.

Without the build script: copy `SKILL.md`'s content into a `.cursor/rules/*.mdc` file
yourself, or just say "Read SKILL.md at `<clone path>` and follow it for this repo."

### Gemini CLI
*(installed and format-verified 2026-08-31; not live-tested - blocked on an authenticated
Google account, not a capability gap; see `tests/agent-bundle-verification.md`)*

Copy `dist/.gemini/extensions/oss-launch/` into `.gemini/extensions/` (project) or
`~/.gemini/extensions/` (global). It's a real Gemini CLI extension: `gemini-extension.json`
manifest + a `/oss-launch` custom command (`commands/oss-launch.toml`) + `GEMINI.md`
context file, per Gemini CLI's documented extension format.

### Windsurf
*(format-verified, not live-tested; see verification status above)*

Copy `dist/.windsurf/rules/oss-launch.md` (the rule) and `dist/.windsurf/oss-launch/`
(its payload) into your project. Windsurf's rule format is close enough to Cursor's that
the same emitter produces both: YAML frontmatter plus the skill body, with
`trigger: model_decision` playing the part of Cursor's `alwaysApply: false` (the model
decides from the `description`, which again comes straight from `SKILL.md`).

### Aider
*(format-verified, not live-tested; see verification status above)*

Copy the contents of `dist/.aider-bundle/` into your project: `CONVENTIONS.md`,
`.aider.conf.yml`, and the `.aider/oss-launch/` payload.

Aider has no rules directory and no trigger matching. It reads whatever files the config
names into every session, so the skill lands as an always-on conventions file rather than
a rule the model opts into. `CONVENTIONS.md` therefore states its own trigger conditions
up front and tells the model to ignore it otherwise. If you don't want it loaded into
every session, drop the `read:` entry from `.aider.conf.yml` and pass
`--read CONVENTIONS.md` only when you need it.

### Any other agent with shell + file access (plain chat, and anything not listed above)
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
generation step (`SKILL.md` step 3: filling `templates/` with the repo's real name,
owner, stack, and license) from a config file instead of an agent asking questions. See
`templates/oss-launch.config.example`. It skips README.md (prose generation is genuinely
agent-only) and never overwrites an existing file.

## What any harness needs to run this

- Shell/bash execution, to run `scripts/*.sh`
- File read + write in the target repo
- `git` and `gh` CLI on `PATH`, for remote detection and repo metadata (`references/scan.md`)
- Network access only for the optional launch modules (demo GIF capture via Playwright,
  `gh repo edit` for metadata). The core scan -> generate flow is fully offline.

## Scope note

`templates/` is the file collection this skill writes into a **user's** repo when
generating an OSS scaffold. The root files (this file, README, LICENSE, `SKILL.md` itself)
describe `oss-launch` the project, not the output it produces. Don't confuse the two when
adapting this AGENTS.md for a harness you're integrating.
