# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## [1.0.1] - 2026-07-31

### Added
- README: Contributing & security section linking CONTRIBUTING.md, CODE_OF_CONDUCT.md,
  and SECURITY.md, plus stars/last-commit badges and a roadmap pointer.
- `.editorconfig` (dogfooding the repo's own template; was flagged optional by its own
  `audit.sh`).

### Fixed
- LICENSE: removed a copy-pasted note referencing a different repo's UI-component
  sourcing (Components) that had no relevance here and broke GitHub's license
  auto-detector (was showing "Other" instead of Apache-2.0).
- SKILL.md: added an explicit Limitations section (license templates supported, README
  generation is agent-only, never publishes on its own, stack coverage).
- `scripts/generate-media.sh` used `-c:v libpal`, not a real ffmpeg encoder, instead of
  the standard two-pass palettegen/paletteuse workflow.
- `templates/README.md` hardcoded an MIT badge and footer regardless of the chosen
  license; every other license reference uses `{{LICENSE}}`.
- `scripts/audit.sh` scored a nonexistent `REPO_PATH` as 0/16 instead of erroring, so a
  typo'd path looked like a catastrophically bare repo (#26).
- `scripts/apply.sh` skipped `pyproject.toml` when auto-detecting a version, silently
  discarding the declared version of every Python repo scaffolded headlessly (#24).
- `scripts/build-agent-dirs.sh` hardcoded the Gemini extension version as `1.0.0`; it is
  now derived from the CHANGELOG, falling back to the nearest tag (#27).
- `templates/CONTRIBUTING.md` linked to `.md` issue templates, but the generated files
  are `.yml`, so every scaffolded repo shipped two dead links (#20).
- The 8 generated CI templates pinned `actions/checkout@v4` while this repo's own
  workflows were already on v7, handing every scaffolded repo a stale-action PR (#21).
- `scripts/release.sh` derived the current version of a manifest-less repo from
  `git describe`, which only walks tags reachable from HEAD. A tag stranded by a history
  rewrite was skipped silently and the next release regressed to an older version line
  (this repo hit exactly that: a `patch` bump off `v1.0.0` produced `v0.4.1`). It now
  reads the CHANGELOG's newest released heading, falling back to `git describe`.

### Changed
- `SKILL.md`'s scan step now lists all 9 supported stack markers; `Gemfile`,
  `pom.xml`/`build.gradle` and `Package.swift` were missing (#22).
- `AGENTS.md` and the README now state per-harness verification status: Claude Code is
  dogfooded, while the Codex CLI, Cursor and Gemini CLI bundles are built to each
  platform's documented format but not live-trigger-tested (#15).
- README demo refreshed to the current workflow clip, with the source mp4 alongside it.

## [1.0.0] - 2026-07-08

Stable release. Scans a repo, generates a tailored open-source file collection, runs
headless or agent-driven, and works across four agent harnesses.

> **Note on the `v1.0.0` git tag (#30).** The tag is orphaned. It points at commit
> `c3940fe`, which the July 17 history rewrite (stripping `GROWTH.md` out of the release
> commit and force-pushing) left off `main`. The equivalent commit now on `main` is
> `ae46411 chore: release v1.0.0`, so `git merge-base --is-ancestor v1.0.0 HEAD` fails and
> `git describe` skips the tag entirely. The tag is deliberately **not** force-moved:
> re-pointing a published tag silently changes what an already-fetched `v1.0.0` resolves
> to for anyone who cloned before the fix. Nothing reads it any more, since `release.sh`
> derives the current version from this file rather than from `git describe` (fixed in
> 1.0.1). **If you want a tag that is genuinely reachable from `main`, use `v1.0.1`** —
> it is the practical equivalent of this release plus that fix.

### Added
- Headless `scripts/apply.sh`: runs scan -> generate -> re-audit from a config file, no
  agent loop. Never overwrites an existing file; skips README.md's prose generation
  (agent-only) rather than emitting boilerplate.
- Stack detection + templates for PHP, .NET, Ruby, Java (Maven + Gradle), and Swift,
  alongside the original Node/Python/Rust/Go coverage.
- `AGENTS.md` + `scripts/build-agent-dirs.sh`: ready-to-copy skill bundles for Claude
  Code, Codex CLI, Cursor, and Gemini CLI from a single `SKILL.md`, each verified
  structurally against that platform's own documented format.
- `example/`: a real before/after `/oss-launch` run (1/16 -> 16/16 audit score) instead
  of hand-written boilerplate claims.
- `tests/run.sh`: CI-asserted `audit.sh` scoring against empty/partial/full fixtures.
- `scripts/check-placeholders.sh`: CI check that every template token is documented and
  that a real generated run leaves zero unresolved `{{TOKENS}}`.
- CI now runs actionlint against every generated CI workflow template, and shellcheck
  passes at default (not just error) severity.
- `.github/workflows/release.yml` for tagged releases.
- `templates/FUNDING.yml`, `CITATION.cff`, `.editorconfig`.

### Fixed
- `references/generate.md`'s placeholder-token map had drifted ~25 tokens out of sync
  with what `templates/` actually use, including a real naming mismatch
  (`SECURITY_CONTACT` documented, `SECURITY_EMAIL` used). Regenerated from source, now
  CI-enforced so it can't drift silently again.
- Word-splitting risk in this repo's own CI and the generated `generic-ci.yml` template's
  shellcheck invocation (caught by actionlint's embedded shellcheck integration).

[1.0.0]: https://github.com/AnayDhawan/oss-launch/releases/tag/v1.0.0
