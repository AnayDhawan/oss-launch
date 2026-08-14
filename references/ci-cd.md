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
      - uses: actions/checkout@v7
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

## Keeping the pins in `templates/` current

The action refs inside `templates/.github/workflows/*.yml` are copied verbatim into every
repo `apply.sh` scaffolds. A stale pin here is worse than a stale pin in an ordinary repo:
it hands a brand-new project an immediate dependabot PR, from a tool whose pitch is that
your repo is already set up correctly. Dependabot does not help, because it only updates
workflows it can see under `.github/`, and these live under `templates/`.

`scripts/check-action-pins.sh` is the watch. It reads every `uses: <owner>/<repo>@<ref>`
line across the workflow templates, resolves each unique action's newest release (falling
back to tags for actions that never cut releases), and reports any pin whose major version
has fallen behind.

```bash
bash scripts/check-action-pins.sh                    # report to stdout
bash scripts/check-action-pins.sh --report pins.md   # also write markdown
```

Exit code is 0 when every pin is current and 1 when drift is found.
`.github/workflows/check-template-action-pins.yml` runs it on the 1st of each month (plus
`workflow_dispatch`) and keeps a **single** `action-pins`-labelled tracking issue in sync:
opened on first drift, commented on subsequent runs, and closed automatically once every
pin is current again. It is deliberately not attached to `push`/`pull_request`, since it
depends on upstream release feeds and must never block a contributor's PR.

Pins that are not version refs (a commit SHA, or a moving branch) are reported for a human
look rather than failed, since there is no major version to compare.
