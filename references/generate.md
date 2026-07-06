# generate.md — filling the OSS file collection

Generate from `templates/`, adapted to the scanned repo. Boilerplate that still says
`{{REPO}}` is a bug.

## Placeholder map
| Token | Source |
|-------|--------|
| `{{OWNER}}` | git remote owner, or asked |
| `{{REPO}}` | git remote repo name, or manifest `name`, or folder name |
| `{{AUTHOR}}` | asked (copyright holder); default to owner's display name |
| `{{YEAR}}` | current year |
| `{{LICENSE}}` | chosen SPDX id (`Apache-2.0` default, or `MIT`) |
| `{{SECURITY_CONTACT}}` | asked: email, or "GitHub Security Advisory" |
| `{{TAGLINE}}` | asked, or first sentence of existing README / manifest description |
| `{{STACK}}` | detected (Node, Python, Rust, ...) |
| `{{VERSION}}` | manifest version field, or latest git tag, or `0.1.0` if neither exists |

## Per-file rules
- **LICENSE** — copy `templates/LICENSE-apache.txt` (default) or `LICENSE-mit.txt`; fill
  `{{YEAR}} {{AUTHOR}}`. Match the `license` field in the manifest if present; if they
  disagree, ask which wins and fix both.
- **README.md** — if absent, build from `templates/README.md` following
  `readme-anatomy.md` (pitch, demo slot, quick start, features, usage, contributing,
  license). If present, only ADD missing sections and a badges row; never rewrite prose.
- **CONTRIBUTING / CODE_OF_CONDUCT / SECURITY** — copy templates, fill contact +
  `{{REPO}}`. Skip CONTRIBUTING + a heavy CoC if the user said outside contributions are
  not wanted (a short CoC + SECURITY is still fine).
- **CHANGELOG.md** — `templates/CHANGELOG.md`, Keep a Changelog, seed `## [Unreleased]`
  plus the current version if one exists.
- **.gitignore** — pick `templates/gitignore/<stack>.gitignore`; merge into an existing one
  rather than replacing.
- **.github/** — `ISSUE_TEMPLATE/{config.yml,bug_report.yml,feature_request.yml}`,
  `PULL_REQUEST_TEMPLATE.md`, `dependabot.yml` (only if the repo has dependencies),
  `workflows/<stack>-ci.yml` filled with the detected test/build/lint commands.
- **.editorconfig** — `templates/.editorconfig`. No placeholders, always safe to add if
  absent; skip only if the repo already has one.
- **CITATION.cff** — `templates/CITATION.cff`, only if the repo is citable (has a paper/DOI,
  or the user says so when asked). Do not offer this for ordinary app/tooling repos.
- **.github/FUNDING.yml** — `templates/FUNDING.yml`, only if the user wants sponsorship
  links; all platform lines ship commented out, uncomment only what the user confirms.

## Don't-overwrite protocol
1. If the target file is absent or trivially empty -> write it.
2. If it exists with real content -> show a unified diff of the proposed change and ask
   before applying. Default to augment, not replace.
3. Always summarize at the end: created / updated / skipped (already good) / manual TODO.
