# Example: a real `/oss-launch` run

This is a real, generated artifact - not hand-written boilerplate. `before/` and `after/` are
the actual output of `demo/scaffold.sh` (the same script that builds the demo GIF fixture),
running the real `templates/` payload through the real `scripts/audit.sh` checklist.

- **`before/`** - a bare fixture repo (`widget-cli`, a tiny Node CLI): `package.json`, one
  source file, a one-line README. No LICENSE, no CONTRIBUTING, no CI, nothing.
- **`after/`** - the same repo after the full OSS file collection is generated and adapted:
  LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, `.gitignore`, `.editorconfig`,
  GitHub issue/PR templates, dependabot config, and a CI workflow - all filled with this
  fixture's real name, owner, and license, not `{{REPO}}` placeholders.
- **`before-audit.txt`** / **`after-audit.txt`** - the actual `scripts/audit.sh` output
  against each state: **1/16 (6%)** before, **16/16 (100%)** after.

Notice `CITATION.cff` and `.github/FUNDING.yml` are correctly *not* generated here and show
as optional in `after-audit.txt` - this fixture is an ordinary CLI tool, not a citable
research artifact or a project seeking sponsorship, so the workflow correctly skips them
rather than dumping every possible file (see `references/generate.md`, "emitted when
relevant").

## Reproduce it yourself

```bash
bash demo/scaffold.sh init  /tmp/widget-cli   # builds the "before" state
bash scripts/audit.sh /tmp/widget-cli         # 1/16
bash demo/scaffold.sh apply /tmp/widget-cli   # generates the OSS file collection
bash scripts/audit.sh /tmp/widget-cli         # 16/16
```
