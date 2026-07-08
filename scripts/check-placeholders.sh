#!/usr/bin/env bash
# check-placeholders.sh — catches the two failure modes #14 found by hand:
#   1. a template uses a {{TOKEN}} that references/generate.md doesn't document
#      (the doc and templates/ have drifted apart)
#   2. a real generated run leaves an unresolved {{TOKEN}} in the output
# Run with no args. Exits non-zero on either failure.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0

echo "── Checking templates/ tokens are all documented in generate.md ──"
DOCUMENTED="$(grep -o '{{[A-Z_0-9]*}}' "$ROOT/references/generate.md" | sort -u)"
USED="$(grep -rho '{{[A-Z_0-9]*}}' "$ROOT/templates" | sort -u)"
UNDOCUMENTED="$(comm -23 <(echo "$USED") <(echo "$DOCUMENTED"))"
if [ -n "$UNDOCUMENTED" ]; then
  echo "FAIL: templates use tokens not documented in references/generate.md:"
  echo "  ${UNDOCUMENTED//$'\n'/$'\n  '}"
  FAILURES=$((FAILURES + 1))
else
  echo "OK: every template token is documented."
fi

echo ""
echo "── Checking a real generated run leaves no unresolved tokens ──"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
bash "$ROOT/demo/scaffold.sh" init "$TMP/fixture" >/dev/null
bash "$ROOT/demo/scaffold.sh" apply "$TMP/fixture" >/dev/null
LEAKED="$(grep -rno '{{[A-Z_0-9]*}}' "$TMP/fixture" 2>/dev/null | sed "s#$TMP/fixture/#  #" || true)"
if [ -n "$LEAKED" ]; then
  echo "FAIL: unresolved {{TOKEN}} left in generated output:"
  echo "$LEAKED"
  FAILURES=$((FAILURES + 1))
else
  echo "OK: no leftover tokens in a real generated fixture."
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "Placeholder checks passed."
  exit 0
else
  echo "$FAILURES placeholder check(s) failed."
  exit 1
fi
