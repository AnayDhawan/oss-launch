# scan.md — how to scan a repo before generating

Goal: know the stack, what already exists, the git identity, and whether anything unsafe
would leak, before writing a single file.

## Stack detection
| Marker file | Stack | Test / build / lint hints |
|-------------|-------|---------------------------|
| `package.json` | Node / JS / TS | `npm test`, `npm run build`, `npm run lint`; read `scripts` |
| `pyproject.toml` / `setup.py` | Python | `pytest`, `ruff`/`flake8`, `python -m build` |
| `Cargo.toml` | Rust | `cargo test`, `cargo build`, `cargo clippy` |
| `go.mod` | Go | `go test ./...`, `go build ./...`, `go vet` |
| `composer.json` | PHP | `composer test` |
| `*.csproj` / `*.sln` | .NET | `dotnet test`, `dotnet build` |
| none of the above | docs / data / skill | no build; lint markdown only |

Read the manifest: name, version, `license` field, declared scripts. These pre-fill
`{{REPO}}`, `{{LICENSE}}`, `{{STACK}}`, and the CI commands.

## Existing-file inventory
Check presence (this is what `scripts/audit.sh` automates):
`README.md`, `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`,
`CHANGELOG.md`, `.gitignore`, `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`
(or lowercase), `.github/dependabot.yml`, `.github/workflows/*`.

For an existing README, note which sections are already present so you augment instead of
overwrite (see `generate.md`).

## Git identity
```bash
git -C <repo> remote -v              # origin URL -> {{OWNER}}/{{REPO}}
git -C <repo> rev-parse --abbrev-ref HEAD   # default branch
gh repo view --json visibility,nameWithOwner 2>/dev/null   # public/private + slug
```
No remote yet => ask for the intended `owner/repo`, or leave badge placeholders.

## Secret + brand-leak scan (every run)
Run before generating and again before any public push. Flag, do not auto-fix:
```bash
# tracked files only; never read .git internals
git -C <repo> ls-files | grep -E '(^|/)\.env($|\.)' || true
grep -rInE '(api[_-]?key|secret|token|password|bearer)\s*[:=]' <repo> \
  --include='*.*' -l 2>/dev/null | grep -vE '\.(lock|md)$' || true
# personal / machine-specific absolute paths
grep -rIn -E '([A-Za-z]:\\\\Users\\\\|/home/[a-z]+/|/Users/[a-z]+/)' <repo> \
  --include='*.*' 2>/dev/null | head || true
```
Also eyeball for: internal hostnames, private repo names, client names, and any
"do not ship" notes. If the repo is going public, a single leaked credential is a stop.
