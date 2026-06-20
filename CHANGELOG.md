# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-06-21

First public release. A Claude Code skill that scans a repository and generates a tailored
open-source file collection, then helps launch it.

### Added
- `/oss-launch` workflow in SKILL.md: scan (stack, existing files, git remote, secret and
  brand-leak check), report gaps, ask only what cannot be inferred, generate adapted files,
  re-audit, and offer launch modules on demand.
- `references/`: scan, generate, README anatomy, GitHub metadata, CI/CD, release, launch
  playbook, and media guides (heavy detail loaded on demand).
- `templates/`: Apache-2.0 and MIT license payloads, README, CONTRIBUTING, CODE_OF_CONDUCT,
  SECURITY, CHANGELOG, `.gitignore` variants (node, python, go, rust, generic), `.github/`
  issue forms + PR template + dependabot, and node/python/generic CI workflows.
- `scripts/`: `audit.sh` (relative-path gap checklist), `release.sh`, `setup-labels.sh`,
  `generate-media.sh`, `update-readme-with-gif.sh`. All resolve their own root, so they run
  from a clone or the installed skill location.
- `launch/`: Show HN, Reddit, and YouTube post templates plus a screenshot storyboard.

[0.4.0]: https://github.com/AnayDhawan/oss-launch/releases/tag/v0.4.0
