#!/usr/bin/env bash
# Demo helper: builds a bare fixture repo, then fills it with the OSS collection from
# templates/, so `audit.sh` visibly goes from a low score to 16/16. Used by the demo GIF
# (demo/oss-launch.tape). Not part of the skill runtime.
#
# Usage:
#   bash demo/scaffold.sh init  <dir>   # create a bare demo project (low audit score)
#   bash demo/scaffold.sh apply <dir>   # generate the OSS files into it (16/16)
#
# shellcheck disable=SC2034  # identity vars below are consumed by fill() in
# scripts/lib/fill-templates.sh, which shellcheck can't statically resolve through
# the dynamic $ROOT path.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$ROOT/templates"
# shellcheck source=scripts/lib/fill-templates.sh
source "$ROOT/scripts/lib/fill-templates.sh"

CMD="${1:-}"
DIR="${2:-}"
[ -z "$CMD" ] || [ -z "$DIR" ] && { echo "usage: scaffold.sh init|apply <dir>"; exit 1; }

# demo identity used to fill template placeholders
OWNER="acme"; REPO="widget-cli"; AUTHOR="Jane Dev"; YEAR="2026"
LICENSE="Apache-2.0"; CONTACT="security@acme.dev"
TAGLINE="A tiny CLI that resizes widgets"; STACK="Node"; ECOSYSTEM="npm"; TEST_COMMAND="npm test"
PROJECT_NAME="$REPO"; INSTALL_COMMAND="npm install"
COPY_ENV_COMMAND="(no .env required)"; DEV_START_COMMAND="npm test"
SETUP_NOTES="That's it - no .env, no database, no build step needed for local development."
VERIFY_COMMAND="npm test"
GOOD_FIRST_ISSUES_LIST="(check the issues tab for the current list)"
STYLE_RULE_1="Use plain Node.js - no framework dependencies"
STYLE_RULE_2="Match the existing code style (2-space indent, semicolons)"
STYLE_RULE_3="Add a test for any new behavior"
PROJECT_SPECIFIC_PR_RULE="Keep the CLI dependency-free where possible"
COMMUNITY_LINK="Open an issue or discussion on GitHub - no separate chat server yet."
CURRENT_MAJOR="0"; SECURITY_EMAIL="$CONTACT"; CONTACT_EMAIL="$CONTACT"
INITIAL_VERSION="0.1.0"; RELEASE_DATE="$YEAR-01-01"
INITIAL_FEATURE_1="Core resize command"; INITIAL_FEATURE_2="Published to npm"
# fill() is provided by scripts/lib/fill-templates.sh (sourced above)

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
    cp "$TPL/.editorconfig" .editorconfig
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
    while IFS= read -r f; do fill "$f" 2>/dev/null || true; done < <(find .github -type f)
    ;;
  *) echo "usage: scaffold.sh init|apply <dir>"; exit 1 ;;
esac
