---
name: oss-launch
description: Use when taking a repo open source, or hardening one that already is. Run /oss-launch and it scans the repo (stack, existing files, git remote, secrets), asks only what it cannot infer, then generates a tailored OSS file collection (README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, .gitignore, .github/ issue + PR templates, CI/CD). Also covers launch (GitHub metadata, badges, Show HN, Reddit, YouTube), release cadence (SemVer + CHANGELOG), and demo-GIF generation. Triggers on "open source this", "OSS checklist", "prep for launch", "make this repo public", "add a license / contributing / security policy", "Show HN", "release workflow", "star growth", "get contributors".
---
# oss-launch

Turn a repo into a credible open-source project: scan what exists, fill the gaps with
adapted (not boilerplate) files, then optionally launch it.

`templates/` holds the payload this skill writes into a USER's repo. The root files
(README, LICENSE, etc.) describe oss-launch itself. Never confuse the two.

## Run (when invoked)

Work top to bottom. Do not dump all files blindly; scan first, then fill only real gaps.

**0. Scan the repo** (details: `references/scan.md`)
- Stack: `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `composer.json` /
  `*.csproj` -> language, package manager, test/build/lint commands.
- Existing OSS files present vs missing: README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT,
  SECURITY, CHANGELOG, `.gitignore`, `.github/` templates, CI workflows.
- Git: `git remote -v` -> `{{OWNER}}/{{REPO}}` + default branch. `gh repo view` -> public?
- Declared license (`package.json` "license" field / existing `LICENSE`).
- Demo asset present? (screenshot / gif in README or `docs/`).
- **Secret + brand-leak scan** (do this every time, even private->public):
  `.env`, API keys, tokens, hardcoded absolute/personal paths, internal-only references.
  If anything leaks, STOP and surface it before generating or publishing anything.

**1. Report** the findings and a gap table. Run the audit for the checklist:
```bash
bash scripts/audit.sh .
```

**2. Ask only what cannot be inferred** (batch into one question round):
license (if undeclared), author / copyright holder + year, security contact,
project type (library / app / CLI / skill / service), are outside contributions wanted,
distribution target (npm / pypi / none), one-line tagline. Skip any the scan answered.

**3. Generate** the file collection from `templates/`, adapted (details: `references/generate.md`):
- Fill placeholders: `{{OWNER}} {{REPO}} {{AUTHOR}} {{YEAR}} {{LICENSE}}`
  `{{SECURITY_CONTACT}} {{TAGLINE}} {{STACK}}`.
- Pick the stack-appropriate `.gitignore` (`templates/gitignore/`) and CI workflow
  (`templates/.github/workflows/`).
- LICENSE: `templates/LICENSE-apache.txt` (default) or `LICENSE-mit.txt`.
- **Never overwrite an existing non-trivial file without showing a diff and confirming.**
  Prefer to augment (e.g. add missing README sections) over clobbering.

**4. Re-audit** and report: what was created, what was updated, what is still manual
(demo GIF, real security email, topics). Aim for a clean `scripts/audit.sh .` pass.

**5. Offer launch modules on demand** (do not auto-run any of these):
| Module | Reference | Tool |
|--------|-----------|------|
| README anatomy (50-star vs 1000-star) | `references/readme-anatomy.md` | - |
| GitHub metadata: topics, description, badges, star-ask | `references/github-metadata.md` | `gh repo edit` |
| CI/CD baseline + when to add each workflow | `references/ci-cd.md` | `templates/.github/workflows/` |
| Release: SemVer + CHANGELOG + tag + GH release + npm/pypi | `references/release.md` | `scripts/release.sh` |
| Standard GitHub labels | - | `scripts/setup-labels.sh <owner/repo>` |
| Demo GIF / screenshot generation | `references/media.md`, `setup/MEDIA_SETUP.md` | `scripts/generate-media.sh`, `scripts/update-readme-with-gif.sh` |
| Launch playbook: Show HN, Reddit, YouTube, star growth | `references/launch-playbook.md` | `launch/*` |

## Rules
- Scan before you write. A gap table beats a wall of generated files.
- Adapt, do not paste. Every emitted file gets the repo's real name, owner, stack, license.
- Leaked secret or personal path => stop and report; never bake it into a public file.
- Public push is irreversible and outward-facing: show the `gh repo create` / push command
  and the leak-scan result, and get explicit confirmation first.
- Apache-2.0 is the default license here; offer MIT when the user prefers minimal ceremony.

## Scripts
| Script | Purpose | Args |
|--------|---------|------|
| `audit.sh` | Gap checklist with relative fix hints | `[REPO_PATH]` (default `.`) |
| `release.sh` | SemVer bump + CHANGELOG + tag + GH release | `patch\|minor\|major\|x.y.z` |
| `setup-labels.sh` | Create standard OSS labels via `gh` | `[owner/repo]` |
| `generate-media.sh` | Playwright screenshots + ffmpeg GIF | `--storyboard YAML` or `--url URL` |
| `update-readme-with-gif.sh` | Insert GIF into README above Quick Start | `--readme`, `--gif` |

All scripts resolve their own root path, so they run from a clone or from the installed
skill location without edits.
