#!/usr/bin/env bash
# check-doc-action-refs.sh: keeps the GitHub Actions versions shown in PROSE in step with
# the ones actually pinned in workflows.
#
# The gap this closes: dependabot watches .github/workflows/, and check-action-pins.sh
# watches templates/.github/workflows/, but nothing watches the worked examples in
# references/*.md. references/ci-cd.md really did keep showing actions/setup-node@v4 long
# after every real workflow had moved to v7, and neither watcher could see it.
#
# This is a pure consistency check against what this repo already pins, so it needs no
# network and no gh CLI: it is safe to run on every PR, unlike check-action-pins.sh.
#
# Usage: bash scripts/check-doc-action-refs.sh
# Exit codes: 0 = docs agree with the pins, 1 = drift found.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Where the truth lives: the real workflows, and the templates shipped to users.
PIN_SOURCES=("$ROOT/.github/workflows" "$ROOT/templates/.github/workflows")
# Where prose lives. Anything here that shows a version must match.
DOC_FILES=("$ROOT"/references/*.md "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/SKILL.md")

USES_RE='uses:[[:space:]]*[A-Za-z0-9._-]+/[A-Za-z0-9._/-]+@[A-Za-z0-9._-]+'

# --- collect the canonical ref per action from the workflow sources --------------------
# "<action> <ref>" pairs. An action pinned to two different refs across the sources has a
# problem of its own, reported separately rather than silently picking one.
PINS="$(
  for dir in "${PIN_SOURCES[@]}"; do
    [ -d "$dir" ] || continue
    grep -rhoE "$USES_RE" "$dir"/*.yml "$dir"/*.yaml 2>/dev/null
  done \
    | sed -E 's/.*uses:[[:space:]]*//' \
    | awk -F@ '{ print $1, $2 }' \
    | sort -u
)"

if [ -z "$PINS" ]; then
  echo "check-doc-action-refs.sh: no pinned actions found in any workflow source." >&2
  exit 1
fi

canonical_ref_for() {  # canonical_ref_for <action> -> the ref(s) it is pinned to
  awk -v action="$1" '$1 == action { print $2 }' <<<"$PINS" | sort -u
}

FAILURES=0
INCONSISTENT=""

echo "── Checking action versions in prose against the real pins ──"

for doc in "${DOC_FILES[@]}"; do
  [ -f "$doc" ] || continue
  rel="${doc#"$ROOT"/}"

  # grep -n gives "<line>:uses: <action>@<ref>"; awk splits it into three clean fields so
  # the loop body does no string surgery of its own.
  while read -r lineno action doc_ref; do
    [ -z "$action" ] && continue

    mapfile -t pinned < <(canonical_ref_for "$action")

    if [ "${#pinned[@]}" -eq 0 ]; then
      # A doc may legitimately name an action this repo does not use. Not drift.
      continue
    fi

    if [ "${#pinned[@]}" -gt 1 ]; then
      INCONSISTENT="${INCONSISTENT}  $action is pinned to ${pinned[*]} across workflows; docs cannot match all of them
"
      continue
    fi

    if [ "$doc_ref" != "${pinned[0]}" ]; then
      echo "  DRIFT  $rel:$lineno shows $action@$doc_ref, workflows pin @${pinned[0]}"
      FAILURES=$((FAILURES + 1))
    fi
  done < <(grep -noE "$USES_RE" "$doc" 2>/dev/null | awk -F'uses:' '
    {
      split($1, prefix, ":")
      ref = $2
      gsub(/^[ \t]+/, "", ref)
      split(ref, parts, "@")
      print prefix[1], parts[1], parts[2]
    }')
done

if [ -n "$INCONSISTENT" ]; then
  echo ""
  echo "Actions pinned inconsistently across workflows (fix the pins, not the docs):"
  printf '%s' "$INCONSISTENT"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "OK: every action version shown in prose matches what the workflows pin."
  exit 0
fi
echo "$FAILURES doc/pin mismatch(es). Update the prose to match the workflows."
exit 1
