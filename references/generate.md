# generate.md — filling the OSS file collection

Generate from `templates/`, adapted to the scanned repo. Boilerplate that still says
`{{REPO}}` is a bug.

## Placeholder map

Two different modes. Get this wrong and you either leave literal `{{TOKENS}}` in a shipped
file, or hand-write prose into a field meant for real substitution.

**Literal substitution** — CONTRIBUTING.md, SECURITY.md, CHANGELOG.md, CODE_OF_CONDUCT.md,
LICENSE-*.txt: every `{{TOKEN}}` is a straight find/replace with a real value. No unresolved
token may survive into the written file (see #10's CI leak check).

**Prose generation** — README.md: the agent writes fresh sentences for each slot (pitch,
features, usage examples), it is not a mechanical find/replace. Its tokens below are content
*slots*, not substitution variables — see `readme-anatomy.md` for what makes each slot good.

### Core tokens (used across multiple templates)
| Token | Source |
|-------|--------|
| `{{OWNER}}` | git remote owner, or asked |
| `{{REPO}}` | git remote repo name, or manifest `name`, or folder name |
| `{{PROJECT_NAME}}` | human-readable project name, usually `{{REPO}}` title-cased or asked |
| `{{AUTHOR}}` | asked (copyright holder); default to owner's display name |
| `{{YEAR}}` | current year |
| `{{LICENSE}}` | chosen SPDX id (`Apache-2.0` default, or `MIT`) |
| `{{SECURITY_EMAIL}}` | asked once as "security/conduct contact", or "GitHub Security Advisory" |
| `{{CONTACT_EMAIL}}` | same value as `{{SECURITY_EMAIL}}` unless the user gives a separate one |
| `{{TAGLINE}}` | asked, or first sentence of existing README / manifest description |
| `{{STACK}}` | detected (Node, Python, Rust, PHP, .NET, Ruby, Java, Swift, ...) |
| `{{VERSION}}` | manifest version field, or latest git tag, or `0.1.0` if neither exists |
| `{{CURRENT_MAJOR}}` | major version number from `{{VERSION}}`, for SECURITY.md's supported-versions table |
| `{{ECOSYSTEM}}` | dependabot `package-ecosystem` value (`npm`, `pip`, `cargo`, ...), from detected stack |
| `{{TEST_COMMAND}}` | detected test command, used in the PR template checklist |

### CONTRIBUTING.md-only tokens
| Token | Source |
|-------|--------|
| `{{INSTALL_COMMAND}}` | detected from manifest/lockfile (`npm install`, `pip install -e .`, ...) |
| `{{COPY_ENV_COMMAND}}` | `cp .env.example .env` if one exists, else omit the step |
| `{{DEV_START_COMMAND}}` | detected dev/run script from the manifest |
| `{{SETUP_NOTES}}` | anything a fresh contributor needs that isn't a command (API keys, services) |
| `{{VERIFY_COMMAND}}` | detected test command |
| `{{GOOD_FIRST_ISSUES_LIST}}` | link to the repo's `good first issue` label search, or omit |
| `{{STYLE_RULE_1}}` / `{{STYLE_RULE_2}}` / `{{STYLE_RULE_3}}` | asked, or inferred from linter config present |
| `{{PROJECT_SPECIFIC_PR_RULE}}` | asked; omit the line if none |
| `{{COMMUNITY_LINK}}` | Discord/Discussions link if the user has one, else omit the line |

### CHANGELOG.md-only tokens
| Token | Source |
|-------|--------|
| `{{INITIAL_VERSION}}` | same as `{{VERSION}}` |
| `{{RELEASE_DATE}}` | today's date |
| `{{INITIAL_FEATURE_1}}` / `{{INITIAL_FEATURE_2}}` | 1-2 line summary of what the repo does today, from the scan |

### .github/ templates
`dependabot.yml` uses `{{ECOSYSTEM}}` + `{{OWNER}}`/`{{REPO}}`; `PULL_REQUEST_TEMPLATE.md`
uses `{{TEST_COMMAND}}` + `{{REPO}}`; `ISSUE_TEMPLATE/*.yml` use `{{OWNER}}`/`{{REPO}}` only.

### README.md prose slots (not literal substitution — see mode note above)
`{{ONE_LINE_PITCH}}`, `{{PROBLEM_SENTENCE_1/2}}`, `{{WHO_ITS_FOR}}`, `{{FEATURE_1..5}}`,
`{{OUTCOME_1..5}}`, `{{USAGE_EXAMPLE_1/2}}`, `{{MOST_COMMON_USE_CASE}}`,
`{{SECOND_MOST_COMMON_USE_CASE}}`, `{{HOW_IT_SOLVES}}`, `{{WHAT_HAPPENS_AFTER}}`,
`{{CONSEQUENCE_IF_UNSOLVED}}`, `{{INSTALL_COMMAND}}`, `{{RUN_COMMAND}}`, `{{CONFIG_COMMAND}}`,
`{{CODE_LANG}}`, `{{PACKAGE_NAME}}`, `{{LIVE_URL}}`, `{{DOCS_URL}}`, `{{AUTHOR_NAME}}`,
`{{AUTHOR_URL}}`, `{{TYPE}}`, `{{DEFAULT}}`, `{{OPTION_1/2}}`, `{{PLACEHOLDERS}}` — write real
content for each from the scan + the one round of questions; never emit these literally.

## Per-file rules
- **LICENSE** — copy `templates/LICENSE-apache.txt` (default) or `LICENSE-mit.txt`; fill
  `{{YEAR}} {{AUTHOR}}`. Match the `license` field in the manifest if present; if they
  disagree, ask which wins and fix both.
- **README.md** — if absent, build from `templates/README.md` following
  `readme-anatomy.md` (pitch, demo slot, quick start, features, usage, contributing,
  license). If present, only ADD missing sections and a badges row; never rewrite prose.
- **CONTRIBUTING / CODE_OF_CONDUCT / SECURITY** — copy templates, fill `{{SECURITY_EMAIL}}`
  / `{{CONTACT_EMAIL}}` + `{{REPO}}` (see per-file token tables above). Skip CONTRIBUTING +
  a heavy CoC if the user said outside contributions are not wanted (a short CoC + SECURITY
  is still fine).
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
