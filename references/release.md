# release.md — versioning and shipping

## SemVer
- `MAJOR`: breaking change (old usage stops working).
- `MINOR`: new feature, backwards compatible.
- `PATCH`: bug fix, no new features.
- `0.x.y`: API not stable; move to `1.0.0` when confident.

## CHANGELOG (keepachangelog.com)
```markdown
## [Unreleased]
### Added
### Changed
### Fixed
### Removed

## [1.1.0] - 2026-05-12
### Added
- Regional scraper sharding (europe, americas, asia-oceania, africa-me)
```
- Never paste raw `git log`; it is for devs, not users.
- Categories: Added, Changed, Deprecated, Removed, Fixed, Security.

## Release script
```bash
bash scripts/release.sh patch    # 1.0.0 -> 1.0.1
bash scripts/release.sh minor    # 1.0.0 -> 1.1.0
bash scripts/release.sh 2.0.0    # explicit
```
It detects the manifest (npm / python / rust / tag-only), bumps the version, opens the
CHANGELOG diff for confirmation, commits, tags, pushes, and offers a GitHub release.

## npm / pypi publish checklist
- [ ] `npm run build` (or `python -m build`) passes clean.
- [ ] Version bumped in the manifest.
- [ ] CHANGELOG `Unreleased` rolled into the new version header.
- [ ] `npm pack --dry-run` (or `twine check dist/*`): no secrets, correct entry points.
- [ ] `npm publish --access public` (or `twine upload dist/*`).
- [ ] `git push origin v{{VERSION}}`.
- [ ] `gh release create v{{VERSION}} --generate-notes`.
