#!/usr/bin/env bash
# Demo helper: builds a bare fixture repo, then fills it with the OSS collection from
# templates/, so `audit.sh` visibly goes from a low score to 16/16. Used by the demo GIF
# (demo/oss-launch.tape). Not part of the skill runtime.
#
# Usage:
#   bash demo/scaffold.sh init  <dir>   # create a bare demo project (low audit score)
#   bash demo/scaffold.sh apply <dir>   # generate the OSS files into it (16/16)

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$ROOT/templates"

CMD="${1:-}"
DIR="${2:-}"
[ -z "$CMD" ] || [ -z "$DIR" ] && { echo "usage: scaffold.sh init|apply <dir>"; exit 1; }

# demo identity used to fill template placeholders
OWNER="acme"; REPO="widget-cli"; AUTHOR="Jane Dev"; YEAR="2026"
LICENSE="Apache-2.0"; CONTACT="security@acme.dev"
TAGLINE="A tiny CLI that resizes widgets"; STACK="Node"; ECOSYSTEM="npm"; TESTCMD="npm test"

fill() {  # fill placeholders in a file in place
  sed -i \
    -e "s/{{OWNER}}/$OWNER/g" -e "s/{{REPO}}/$REPO/g" \
    -e "s/{{AUTHOR}}/$AUTHOR/g" -e "s/{{YEAR}}/$YEAR/g" \
    -e "s/{{LICENSE}}/$LICENSE/g" -e "s/{{SECURITY_CONTACT}}/$CONTACT/g" \
    -e "s#{{TAGLINE}}#$TAGLINE#g" -e "s/{{STACK}}/$STACK/g" \
    -e "s/{{ECOSYSTEM}}/$ECOSYSTEM/g" -e "s/{{TEST_COMMAND}}/$TESTCMD/g" \
    "$1"
}

case "$CMD" in
  init)
    rm -rf "$DIR"; mkdir -p "$DIR/src"
    cat > "$DIR/package.json" <<JSON
{ "name": "$REPO", "version": "0.1.0", "description": "$TAGLINE",
  "main": "src/index.js", "scripts": { "test": "node --test" } }
JSON
    printf 'export function resize(w){ return w*2 }\n' > "$DIR/src/index.js"
    printf '# %s\n\nTODO: write docs.\n' "$REPO" > "$DIR/README.md"
    ;;
  apply)
    cd "$DIR"
    # license
    cp "$TPL/LICENSE-apache.txt" LICENSE; fill LICENSE
    # community + meta files
    for f in CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md CHANGELOG.md; do
      cp "$TPL/$f" "$f"; fill "$f"
    done
    cp "$TPL/gitignore/node.gitignore" .gitignore
    # a README that passes the quality checks (badges + quick start + demo)
    cat > README.md <<MD
# $REPO

[![CI](https://github.com/$OWNER/$REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/$OWNER/$REPO/actions)
[![License: $LICENSE](https://img.shields.io/badge/license-$LICENSE-blue)](LICENSE)

$TAGLINE.

![demo](docs/media/demo.gif)

## Quick Start
\`\`\`bash
npm install $REPO
\`\`\`
MD
    # github templates + workflow
    mkdir -p .github/ISSUE_TEMPLATE .github/workflows
    cp "$TPL/.github/ISSUE_TEMPLATE/config.yml" .github/ISSUE_TEMPLATE/
    cp "$TPL/.github/ISSUE_TEMPLATE/bug_report.yml" .github/ISSUE_TEMPLATE/
    cp "$TPL/.github/ISSUE_TEMPLATE/feature_request.yml" .github/ISSUE_TEMPLATE/
    cp "$TPL/.github/PULL_REQUEST_TEMPLATE.md" .github/
    cp "$TPL/.github/dependabot.yml" .github/; fill .github/dependabot.yml
    cp "$TPL/.github/workflows/node-ci.yml" .github/workflows/ci.yml
    for f in $(find .github -type f); do fill "$f" 2>/dev/null || true; done
    ;;
  *) echo "usage: scaffold.sh init|apply <dir>"; exit 1 ;;
esac
