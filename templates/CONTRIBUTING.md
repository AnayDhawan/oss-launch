# Contributing to {{PROJECT_NAME}}

---

## Quick Setup

```bash
git clone https://github.com/{{OWNER}}/{{REPO}}.git
cd {{REPO}}
{{INSTALL_COMMAND}}
{{COPY_ENV_COMMAND}}
{{DEV_START_COMMAND}}
```

{{SETUP_NOTES}}

---

## How to Contribute

### Reporting Bugs
Open an issue using the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include steps to reproduce, expected vs actual behavior, environment.

### Requesting Features
Open an issue using the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

### Submitting a PR

1. Fork the repo and create a branch: `git checkout -b feat/your-feature`
2. Make your changes
3. Verify: `{{VERIFY_COMMAND}}` — must pass clean
4. Open a PR against `main`

---

## Good First Issues

Look for issues labeled [`good first issue`](https://github.com/{{OWNER}}/{{REPO}}/labels/good%20first%20issue).

{{GOOD_FIRST_ISSUES_LIST}}

---

## Code Style

- {{STYLE_RULE_1}}
- {{STYLE_RULE_2}}
- {{STYLE_RULE_3}}

---

## PR Guidelines

- One PR per change — keep scope tight
- PR description must explain *why*, not just *what*
- {{PROJECT_SPECIFIC_PR_RULE}}
- AI-assisted code is welcome — provided you have reviewed and tested the output

---

## Commit Style

[Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add dark mode toggle
fix: correct timezone offset in tournament dates
docs: update quick start steps
```
Types: `feat | fix | docs | style | refactor | perf | test | ci | chore`

---

## Community

{{COMMUNITY_LINK}}
