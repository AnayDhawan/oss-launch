# ci-cd.md: minimum CI/CD every OSS repo needs

Add in this order. Stack-specific starter workflows live in
`templates/.github/workflows/`; fill the test/build/lint commands from the scan.

## 1. CI workflow (`ci.yml`): Node example
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
  # Replace package-ecosystem with your stack:
  # npm | pip | cargo | gomod | composer | nuget | bundler | maven | gradle | swift
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

## When to add each
| Workflow | Add when |
|----------|----------|
| `ci.yml` | Day 1, always |
| `dependabot.yml` | Day 1 if the repo has dependencies |
| `release.yml` | First versioned release |
| `stale.yml` | >20 open issues |

## The opt-in menu

Beyond the stack CI workflow every scaffold gets, four templates are written only when
asked for. All default off, because each one has a real cost if added blindly.

| Template | Config flag | Also requires | Cost of adding it blindly |
|----------|-------------|---------------|---------------------------|
| `coverage-node.yml` / `coverage-python.yml` | `WANT_COVERAGE` | Node or Python, and a detected test runner | a coverage job with nothing to measure just fails CI |
| `release-please.yml` | `WANT_RELEASE_PLEASE` | - | see the warning below |
| `container-build.yml` | `WANT_CONTAINER_BUILD` | a `Dockerfile` or compose file (`detect_docker`) | nothing to build |

`apply.sh` reports when a flag is set but the precondition is not met, rather than
silently writing nothing.

**Coverage.** Codecov needs no token for public repos; a private repo needs a
`CODECOV_TOKEN` secret or the upload step fails. The template's test invocation is a
starting point, not a guess that will fit every runner: adjust it to whatever actually
emits `lcov.info` (Node) or `coverage.xml` (Python).

**release-please is an alternative to `scripts/release.sh`, not an addition.** Pick one:

| | You control | Cost |
|---|---|---|
| `scripts/release.sh` | when to release, what the CHANGELOG says, when the tag lands | needs a human every time |
| `release-please.yml` | nothing; merging the standing release PR cuts the release | your commit messages *become* the CHANGELOG, so every contributor has to write Conventional Commits properly |

Running both means two systems racing to own the version number and the CHANGELOG file.
Delete the one you are not using. Also set `release-type` to match the project
(`node`, `python`, `rust`, `go`, `simple`, ...).

**Container build.** Publishes to `ghcr.io/<owner>/<repo>` using `GITHUB_TOKEN`, so no
secret setup. It builds on every PR (so a broken Dockerfile is caught in review) but
pushes only from `main` and version tags, which is what stops a fork's PR from publishing
an image. The first push creates the package as private; make it public from the repo's
Packages page if you want anonymous pulls.

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
