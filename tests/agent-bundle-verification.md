# Agent bundle verification

What has actually been checked about the bundles `scripts/build-agent-dirs.sh` emits into
`dist/`, and what has not. Tracked by #15.

The distinction this file exists to keep honest:

- **Format-verified** — the bundle matches the harness's documented extension format, and
  its payload is self-contained and runnable. Checked mechanically, re-checkable by anyone.
- **Live-trigger-tested** — a real install of that harness was given a real prompt, and the
  agent was observed pulling in the bundle and following `SKILL.md`. Requires the harness.

Format-verified is not a weaker version of live-trigger-tested. It cannot catch a harness
that silently ignores a rule file, changes its discovery path, or truncates a long
`description`. Those are exactly the failures #15 exists to find.

**Last run: 2026-08-14**, on Windows 11 / Git Bash.

## Status

| Harness | Installed here | Format-verified | Payload runs | Live-trigger-tested |
|---------|----------------|-----------------|--------------|---------------------|
| Claude Code | yes (v2.1.215) | yes | yes | **yes** — dogfooded daily |
| Cursor | yes (v2.2.43) | yes | yes | **no** — see below |
| Codex CLI | no | yes | yes | no |
| Gemini CLI | no | yes | yes | no |

## Why Cursor is still untested despite being installed

Cursor 2.2.43 is installed at `C:\Program Files\cursor`, and its CLI is on `PATH`. That CLI
is a VS Code-style **editor launcher**, not an agent runner:

```
$ cursor --help
Cursor 2.2.43
Usage: cursor.exe [options][paths...]
  -d --diff / -m --merge / -a --add / -g --goto / -n --new-window / -w --wait ...
```

Every option opens, compares, or focuses a window. There is no headless or agent
subcommand, and no separate `cursor-agent` binary on this machine.

Triggering the rule means typing a prompt into the chat pane of a running GUI and reading
what the agent does with it. That cannot be driven or observed from a shell session, so
**installation did not translate into testability**. Recording it as tested would be a lie
that removes the only signal #15 is trying to produce.

This is a finding in itself: "is the harness installed" is the wrong gate for this issue.
The right one is "can the harness be driven non-interactively". Of the four, only Claude
Code and (if installed) the two CLI-based harnesses can be.

## What was verified, 2026-08-14

Run against all four bundles after `bash scripts/build-agent-dirs.sh`.

### 1. Every path `SKILL.md` names resolves inside its own bundle

Each bundle's `SKILL.md` references `references/*.md`, `templates/...`, and `scripts/*.sh`.
A bundle that names a file it did not ship is broken in a way no amount of format
correctness would catch, and the agent only discovers it mid-run.

```
.claude/skills/oss-launch      refs unresolved: 0
.codex/skills/oss-launch       refs unresolved: 0
.cursor/oss-launch             refs unresolved: 0
.gemini/extensions/oss-launch  refs unresolved: 0
```

### 2. The bundled scripts run from the bundle location

`audit.sh` resolves its own root, so it must work from inside a bundle without a separate
clone. Confirmed for all four.

### 3. End-to-end scaffold from a placed Cursor bundle

`dist/.cursor/` copied into a scratch repo as a user would, then run from where it landed:

```
$ bash .cursor/oss-launch/scripts/apply.sh . --config cfg
── apply.sh summary (stack: node) ──
Created (16): LICENSE CONTRIBUTING.md … .github/workflows/stale.yml
Score: 13/16 (81%)
```

This proves the payload is genuinely self-contained: correct stack detection, all 16 files
written, audit re-run, no reference back to the original clone. It does **not** prove
Cursor ever reads `.cursor/rules/oss-launch.mdc`.

### 4. Manifest shape

- `.cursor/rules/oss-launch.mdc` — `description` + `alwaysApply: false` frontmatter, body
  pointing at `.cursor/oss-launch/SKILL.md`.
- `.gemini/extensions/oss-launch/gemini-extension.json` — `name`, `version` (derived from
  the CHANGELOG, not hardcoded, per #27), `contextFileName: GEMINI.md`, alongside
  `commands/oss-launch.toml`.
- `.codex/skills/oss-launch/SKILL.md` — same format as Claude Code, no adaptation.

## What would close #15

For each of Cursor, Codex CLI, and Gemini CLI, in a real install:

1. Copy the bundle into a scratch repo.
2. Prompt the agent with something in the trigger set, e.g. "open source this repo".
3. Confirm it pulls in the bundle **without being told the file path**, which is the whole
   claim being tested.
4. Confirm it follows `SKILL.md`'s order: scan, report a gap table, ask, then generate.
5. Record the harness version, the prompt, and where it deviated.

Step 3 is the one that matters. A harness that only works when you paste the path is a
documentation path, not a skill integration, and `AGENTS.md` already documents that
fallback for every harness.
