# Contributing to widget-cli

---

## Quick Setup

```bash
git clone https://github.com/acme/widget-cli.git
cd widget-cli
npm install
(no .env required)
npm test
```

That's it - no .env, no database, no build step needed for local development.

---

## How to Contribute

### Reporting Bugs
Open an issue using the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include steps to reproduce, expected vs actual behavior, environment.

### Requesting Features
Open an issue using the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

### Submitting a PR

1. Fork the repo and create a branch: `git checkout -b feat/your-feature`
2. Make your changes
3. Verify: `npm test` — must pass clean
4. Open a PR against `main`

---

## Good First Issues

Look for issues labeled [`good first issue`](https://github.com/acme/widget-cli/labels/good%20first%20issue).

(check the issues tab for the current list)

---

## Code Style

- Use plain Node.js - no framework dependencies
- Match the existing code style (2-space indent, semicolons)
- Add a test for any new behavior

---

## PR Guidelines

- One PR per change — keep scope tight
- PR description must explain *why*, not just *what*
- Keep the CLI dependency-free where possible
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

Open an issue or discussion on GitHub - no separate chat server yet.
