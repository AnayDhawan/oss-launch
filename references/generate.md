# generate.md: filling the OSS file collection

Generate from `templates/`, adapted to the scanned repo. Boilerplate that still says
`{{REPO}}` is a bug.

## Placeholder map

Two different modes. Get this wrong and you either leave literal `{{TOKENS}}` in a shipped
file, or hand-write prose into a field meant for real substitution.

**Literal substitution**: CONTRIBUTING.md, SECURITY.md, CHANGELOG.md, CODE_OF_CONDUCT.md,
LICENSE-*.txt: every `{{TOKEN}}` is a straight find/replace with a real value. No unresolved
token may survive into the written file (see #10's CI leak check).

**Prose generation**: README.md: the agent writes fresh sentences for each slot (pitch,
features, usage examples), it is not a mechanical find/replace. Its tokens below are content
*slots*, not substitution variables. See `readme-anatomy.md` for what makes each slot good.

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
| `{{SITE_URL}}` | base URL of the published site, used by `llms.txt` and the `site/` templates. Defaults to `https://{{OWNER}}.github.io/{{REPO}}/`; override in the config for a custom domain. **Trailing slash is required**: `robots.txt` and `sitemap.xml` concatenate onto it |
| `{{DEFAULT_BRANCH}}` | the repo's real default branch, for `blob/<branch>/` links in `llms.txt` and the workflow `branches:` triggers. Read from `refs/remotes/origin/HEAD`, else the checked-out branch, else `main`. Never assume `main`: a `blob/main/` link 404s on a repo still using `master` |

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

### README.md prose slots (not literal substitution, see mode note above)
Every token below is spelled out literally (not `N..M` range shorthand) so the CI
placeholder check (`scripts/check-placeholders.sh`) can verify this list against the
template mechanically:

`{{ONE_LINE_PITCH}}`, `{{PROBLEM_SENTENCE_1}}`, `{{PROBLEM_SENTENCE_2}}`, `{{WHO_ITS_FOR}}`,
`{{HOW_IT_SOLVES}}`, `{{CONSEQUENCE_IF_UNSOLVED}}`, `{{LOGO_PATH}}`, `{{PACKAGE_NAME}}`,
`{{LIVE_URL}}`, `{{DOCS_URL}}`, `{{WHY_1_TITLE}}`, `{{WHY_1_BODY}}`, `{{WHY_2_TITLE}}`,
`{{WHY_2_BODY}}`, `{{WHY_3_TITLE}}`, `{{WHY_3_BODY}}`, `{{WHY_4_TITLE}}`, `{{WHY_4_BODY}}`,
`{{FEATURE_1}}`, `{{FEATURE_2}}`, `{{FEATURE_3}}`, `{{FEATURE_4}}`, `{{FEATURE_5}}`,
`{{OUTCOME_1}}`, `{{OUTCOME_2}}`, `{{OUTCOME_3}}`, `{{OUTCOME_4}}`, `{{OUTCOME_5}}`,
`{{FEATURE_1_BULLETS}}`, `{{FEATURE_2_BULLETS}}`, `{{FEATURE_3_BULLETS}}`,
`{{SCREENSHOT_1_TITLE}}`, `{{SCREENSHOT_1_PATH}}`, `{{SCREENSHOT_2_TITLE}}`,
`{{SCREENSHOT_2_PATH}}`, `{{REQUIREMENTS}}`, `{{RUN_COMMAND}}`, `{{BUILD_COMMAND}}`,
`{{WHAT_HAPPENS_AFTER}}`, `{{OPTION_1}}`, `{{OPTION_2}}`, `{{REQUIRED}}`, `{{DEFAULT}}`,
`{{DESCRIPTION}}`, `{{SHORTCUT_1_KEYS}}`, `{{SHORTCUT_1_ACTION}}`, `{{SHORTCUT_2_KEYS}}`,
`{{SHORTCUT_2_ACTION}}`, `{{TECH_STACK_ROWS}}`, `{{FOLDER_TREE}}`, `{{PRIVACY_SUMMARY}}`,
`{{NETWORK_CALLS}}`, `{{ROADMAP_SHIPPED}}`, `{{ROADMAP_NEXT}}`, `{{CONTRIBUTION_KINDS}}`,
`{{AUTHOR_NAME}}`, `{{AUTHOR_URL}}`, `{{PLACEHOLDERS}}`: write real content for each from the
scan + the one round of questions; never emit these literally. (`{{INSTALL_COMMAND}}`,
`{{TEST_COMMAND}}`, `{{TAGLINE}}`, `{{STACK}}`, `{{YEAR}}`, `{{LICENSE}}`, `{{OWNER}}`,
`{{REPO}}`, `{{PROJECT_NAME}}` also appear here, already documented above, same values.)

Slot shapes, where the name alone is ambiguous:
- `{{FEATURE_n_BULLETS}}`: 2-5 markdown bullets, each one concrete capability. A short fenced
  code example is fine here; this is where a library or CLI shows its usage.
- `{{TECH_STACK_ROWS}}`: one `| Area | Choice |` table row per technology, linked to the
  tool's site where one exists.
- `{{FOLDER_TREE}}`: a real tree of the repo, top two levels, one `# comment` per entry.
  Never invent a folder that is not on disk.
- `{{NETWORK_CALLS}}`: a bullet per external host the project contacts, and why.
- `{{WHY_n_TITLE}}` / `{{WHY_n_BODY}}`: properties of the project as a whole (license,
  local-first, no login, offline). Not a restatement of the features table.

**Optional sections.** The template marks Screenshots, Environment variables, Keyboard
shortcuts and Privacy with `<!-- OPTIONAL -->`. Delete the whole section, marker included,
when it does not apply (no visual output, no configuration, no shortcuts, no user data). An
empty section or a leftover marker is the same bug as a leftover `{{TOKEN}}`. If outside
contributions are not wanted, drop the Contributing section and its nav link too.

## Per-file rules
- **LICENSE**: copy `templates/LICENSE-apache.txt` (default) or `LICENSE-mit.txt`; fill
  `{{YEAR}} {{AUTHOR}}`. Match the `license` field in the manifest if present; if they
  disagree, ask which wins and fix both.
- **README.md**: if absent, build from `templates/README.md` following
  `readme-anatomy.md` (centered header with badges, demo GIF, Why, Features table plus
  per-feature sections, Screenshots, Quick start, Tech stack, Folder structure, Roadmap,
  Contributing, License). This layout is the default for every generated README. If
  present, only ADD missing sections and a badges row; never rewrite prose or reflow an
  existing README into this layout.
- **CONTRIBUTING / CODE_OF_CONDUCT / SECURITY**: copy templates, fill `{{SECURITY_EMAIL}}`
  / `{{CONTACT_EMAIL}}` + `{{REPO}}` (see per-file token tables above). Skip CONTRIBUTING +
  a heavy CoC if the user said outside contributions are not wanted (a short CoC + SECURITY
  is still fine).
- **CHANGELOG.md**: `templates/CHANGELOG.md`, Keep a Changelog, seed `## [Unreleased]`
  plus the current version if one exists.
- **.gitignore**: pick `templates/gitignore/<stack>.gitignore`; merge into an existing one
  rather than replacing.
- **.github/**: `ISSUE_TEMPLATE/{config.yml,bug_report.yml,feature_request.yml}`,
  `PULL_REQUEST_TEMPLATE.md`, `dependabot.yml` (only if the repo has dependencies),
  `workflows/<stack>-ci.yml` filled with the detected test/build/lint commands.
- **.editorconfig**: `templates/.editorconfig`. No placeholders, always safe to add if
  absent; skip only if the repo already has one.
- **CITATION.cff**: `templates/CITATION.cff`, only if the repo is citable (has a paper/DOI,
  or the user says so when asked). Do not offer this for ordinary app/tooling repos.
- **.github/FUNDING.yml**: `templates/FUNDING.yml`, only if the user wants sponsorship
  links; all platform lines ship commented out, uncomment only what the user confirms.

## Don't-overwrite protocol
1. If the target file is absent or trivially empty -> write it.
2. If it exists with real content -> show a unified diff of the proposed change and ask
   before applying. Default to augment, not replace.
3. Always summarize at the end: created / updated / skipped (already good) / manual TODO.
