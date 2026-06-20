# oss-launch

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![Claude Code skill](https://img.shields.io/badge/Claude%20Code-skill-8A63D2)](https://docs.claude.com/en/docs/claude-code)
[![Status: v0.4.0](https://img.shields.io/badge/status-v0.4.0-success)](CHANGELOG.md)

**Take a repo open source the right way.** Run `/oss-launch` and it scans your repo, asks
only what it cannot infer, then generates a tailored open-source file collection: README,
LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, `.gitignore`, GitHub issue and
PR templates, and CI. Then it helps you launch: badges, metadata, releases, demo GIFs, and
a Show HN / Reddit / YouTube playbook.

<!-- demo-placeholder: add a terminal GIF of /oss-launch scanning a repo and filling gaps -->

If this is useful, star it. It helps other solo maintainers find it.

## Why

Most solo projects never get the boring-but-decisive OSS files: a real LICENSE, a
contributing guide, a security policy, a README that pitches in one line. `oss-launch` does
the scan and the scaffolding in one pass, adapted to your stack and repo, instead of
pasting boilerplate that still says `{{REPO}}`.

## Quick start

This is a Claude Code skill. Install it where Claude Code discovers skills:

```bash
git clone https://github.com/AnayDhawan/oss-launch.git ~/.claude/skills/oss-launch
```

Then, inside any repository you want to open source:

```
/oss-launch
```

It will scan, report gaps, ask a few questions, and generate the files. The shell helpers
also run standalone:

```bash
bash ~/.claude/skills/oss-launch/scripts/audit.sh .      # gap checklist for the current repo
```

## What it does

```
/oss-launch
  0. Scan      stack, existing files, git remote, secrets/brand leaks
  1. Report    gap table (scripts/audit.sh)
  2. Ask       license, author, security contact, type, tagline (only what is unknown)
  3. Generate  the OSS file collection from templates/, adapted and placeholder-filled
  4. Re-audit  what was created/updated, what is still manual
  5. Launch    metadata, CI, releases, demo GIF, Show HN / Reddit / YouTube (on demand)
```

## What is in here

| Path | What |
|------|------|
| `SKILL.md` | The skill: the scan to generate workflow Claude follows |
| `references/` | The detail: scan, generate, README anatomy, metadata, CI/CD, release, launch, media |
| `templates/` | The payload written into your repo: LICENSE, README, CONTRIBUTING, CoC, SECURITY, CHANGELOG, `.gitignore` variants, `.github/` templates, CI workflows |
| `scripts/` | `audit.sh`, `release.sh`, `setup-labels.sh`, `generate-media.sh`, `update-readme-with-gif.sh` |
| `launch/` | Ready-to-edit Show HN, Reddit, and YouTube post templates + screenshot storyboard |
| `setup/` | One-time media (Playwright + ffmpeg) setup notes |

`templates/` is the payload emitted into other repos. The root files (this README, LICENSE,
and so on) describe oss-launch itself.

## License

Apache-2.0. See [LICENSE](LICENSE). Files this skill generates into your repo are yours; pick
their license (Apache-2.0 or MIT) when prompted.
