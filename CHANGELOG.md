# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-08

Stable release. Scans a repo, generates a tailored open-source file collection, runs
headless or agent-driven, and works across four agent harnesses.

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
