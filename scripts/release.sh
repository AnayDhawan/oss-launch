#!/usr/bin/env bash
# OSS Release Script — semver bump + CHANGELOG + tag + GH release
# Usage:
#   bash release.sh patch      # 1.0.0 → 1.0.1
#   bash release.sh minor      # 1.0.0 → 1.1.0
#   bash release.sh major      # 1.0.0 → 2.0.0
#   bash release.sh 1.3.0      # explicit version

set -euo pipefail

VERSION_ARG="${1:-}"
if [ -z "$VERSION_ARG" ]; then
  echo "Usage: bash release.sh <patch|minor|major|x.y.z>"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: working tree has uncommitted changes. Commit or stash first."
  exit 1
fi

detect_type() {
  if [ -f "package.json" ]; then echo "npm"
  elif [ -f "pyproject.toml" ]; then echo "python"
  elif [ -f "Cargo.toml" ]; then echo "rust"
  else echo "none"
  fi
}
PROJECT_TYPE=$(detect_type)

get_current_version() {
  case "$PROJECT_TYPE" in
    npm)    node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0" ;;
    python) grep '^version' pyproject.toml | head -1 | sed 's/.*= *"\(.*\)"/\1/' ;;
    rust)   grep '^version' Cargo.toml | head -1 | sed 's/.*= *"\(.*\)"/\1/' ;;
    none)   git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0" ;;
  esac
}

CURRENT=$(get_current_version)
echo "Current version: $CURRENT"

semver_bump() {
  local version="$1" bump="$2"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  case "$bump" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "$major.$((minor + 1)).0" ;;
    patch) echo "$major.$minor.$((patch + 1))" ;;
    *)     echo "$bump" ;;
  esac
}

NEW_VERSION=$(semver_bump "$CURRENT" "$VERSION_ARG")
echo "New version:     $NEW_VERSION"
echo ""
read -r -p "Proceed with release v$NEW_VERSION? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

case "$PROJECT_TYPE" in
  npm)
    npm version "$NEW_VERSION" --no-git-tag-version
    echo "✓ Bumped package.json to $NEW_VERSION"
    ;;
  python)
    sed -i.bak "s/^version = \"$CURRENT\"/version = \"$NEW_VERSION\"/" pyproject.toml
    rm -f pyproject.toml.bak
    echo "✓ Bumped pyproject.toml to $NEW_VERSION"
    ;;
  none)
    echo "ℹ No manifest found — tag-only mode"
    ;;
esac

TODAY=$(date +%Y-%m-%d)
if [ -f "CHANGELOG.md" ]; then
  sed -i.bak \
    "s/## \[Unreleased\]/## [Unreleased]\n\n### Added\n\n### Changed\n\n### Fixed\n\n---\n\n## [$NEW_VERSION] - $TODAY/" \
    CHANGELOG.md
  rm -f CHANGELOG.md.bak
  echo "✓ Updated CHANGELOG.md"
  echo ""
  git diff CHANGELOG.md | head -30
  echo ""
  read -r -p "CHANGELOG looks correct? [y/N] " CHANGELOG_OK
  if [[ ! "$CHANGELOG_OK" =~ ^[Yy]$ ]]; then
    echo "Edit CHANGELOG.md, then re-run."
    exit 0
  fi
fi

git add -A
git commit -m "chore: release v$NEW_VERSION"
echo "✓ Release commit created"

git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
git push origin HEAD
git push origin "v$NEW_VERSION"
echo "✓ Tag v$NEW_VERSION pushed"

if command -v gh &>/dev/null; then
  read -r -p "Create GitHub Release for v$NEW_VERSION? [y/N] " GH_RELEASE
  if [[ "$GH_RELEASE" =~ ^[Yy]$ ]]; then
    RELEASE_NOTES=$(awk "/## \[$NEW_VERSION\]/{flag=1; next} /^## \[/{flag=0} flag" CHANGELOG.md)
    if [ -n "$RELEASE_NOTES" ]; then
      gh release create "v$NEW_VERSION" --title "v$NEW_VERSION" --notes "$RELEASE_NOTES"
    else
      gh release create "v$NEW_VERSION" --title "v$NEW_VERSION" --generate-notes
    fi
    echo "✓ GitHub Release created"
  fi
fi

if [ "$PROJECT_TYPE" = "npm" ]; then
  read -r -p "Publish to npm? [y/N] " NPM_PUBLISH
  if [[ "$NPM_PUBLISH" =~ ^[Yy]$ ]]; then
    npm pack --dry-run
    read -r -p "Publish now? [y/N] " NPM_CONFIRM
    if [[ "$NPM_CONFIRM" =~ ^[Yy]$ ]]; then
      npm publish --access public
      echo "✓ Published to npm"
    fi
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Release v$NEW_VERSION complete."
echo ""
echo "Post-release checklist:"
echo "  [ ] Announce on Twitter/X with demo GIF"
echo "  [ ] Post to r/SideProject or relevant subreddit"
echo "  [ ] Update docs if API changed"
