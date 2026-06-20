# ci-cd.md — minimum CI/CD every OSS repo needs

Add in this order. Stack-specific starter workflows live in
`templates/.github/workflows/`; fill the test/build/lint commands from the scan.

## 1. CI workflow (`ci.yml`) — Node example
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
concurrency:
  group: ${{ github.ref }}
  cancel-in-progress: true
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npm run lint
      - run: npm run build
```

## 2. Dependabot (`dependabot.yml`)
```yaml
version: 2
updates:
  - package-ecosystem: "npm"        # github-actions / pip / cargo / gomod ...
    directory: "/"
    schedule: { interval: "weekly" }
    open-pull-requests-limit: 5
```

## When to add each
| Workflow | Add when |
|----------|----------|
| `ci.yml` | Day 1, always |
| `dependabot.yml` | Day 1 if the repo has dependencies |
| `release.yml` | First versioned release |
| `codeql.yml` | >50 stars or it handles user data |
| `stale.yml` | >20 open issues |
