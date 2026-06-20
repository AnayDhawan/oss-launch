# Security Policy

## Scope

oss-launch is a collection of templates, shell scripts, and guidance. The main risks are:
- a script behaving unexpectedly on a repository, or
- a template leaking something it should not.

The scripts run local `git`, `gh`, Playwright, and ffmpeg commands. Review any script before
running it, as you would any tooling.

## Reporting a vulnerability

Report privately through
[GitHub Security Advisories](https://github.com/AnayDhawan/oss-launch/security/advisories/new).
Do not open a public issue for a security report.

Expect an acknowledgement within 7 days. Please include steps to reproduce and the affected
script or template.

## Supported versions

The latest released version receives fixes. Older versions are not maintained.
