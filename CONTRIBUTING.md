# Contributing to oss-launch

Thanks for helping improve the OSS launch workflow. Contributions are mostly new or better
templates, script fixes, and clearer references.

## Ways to contribute
- **Templates** (`templates/`): improve a generated file, add a stack variant
  (`.gitignore`, CI workflow), or fix a placeholder. Keep everything generic: use
  `{{OWNER}} {{REPO}} {{AUTHOR}} {{YEAR}} {{LICENSE}}` and never hardcode a name or path.
- **Scripts** (`scripts/`): keep them POSIX-friendly bash that resolves its own root via
  `ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`. Run `shellcheck` before opening
  a PR.
- **References / SKILL.md**: keep guidance terse and accurate. The SKILL.md body stays lean;
  long-form detail lives in `references/`.

## Workflow
1. Fork and branch from `main`.
2. Make a focused change.
3. `shellcheck scripts/*.sh` if you touched a script.
4. Open a PR using the template. Describe what and why.

## Ground rules
- No secrets, credentials, or personal paths in any file.
- Templates must stay reusable across projects.
- Be respectful; see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
