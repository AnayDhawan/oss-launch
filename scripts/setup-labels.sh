#!/usr/bin/env bash
# Creates standard OSS GitHub labels via the gh CLI.
# Idempotent: skips labels that already exist.
#
# Usage:
#   bash scripts/setup-labels.sh [owner/repo]              (defaults to the current repo)
#   bash scripts/setup-labels.sh --good-first-issue-seed   print the seeding checklist
#
# The seed flag prints a checklist, it does not create issues. Fabricated "good first
# issues" are worse than none: a newcomer who picks one up and finds it vague, already
# done, or not actually wanted leaves and does not come back.

set -euo pipefail

SEED_ONLY=false
TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --good-first-issue-seed) SEED_ONLY=true; shift ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) echo "setup-labels.sh: unknown option: $1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

print_seed_checklist() {
  cat <<'CHECKLIST'

── Seeding "good first issue": a checklist ──

Three to five real ones at launch is the target. Below that, the label reads as
decorative. Above that, you cannot mentor them all at once.

What to look for in your own backlog and TODOs:

  [ ] A doc gap you already know about. Something you had to explain to someone once,
      or a README section that is thin. Lowest risk, highest completion rate.
  [ ] A test you keep meaning to write for behavior that already works. The correct
      answer is knowable without design decisions, which is the whole point.
  [ ] A hardcoded value that should be a config option, where you already know where
      it should live.
  [ ] One error message that is unhelpful, with a note on what it should say instead.
  [ ] A small, self-contained addition to an existing list or table: one more supported
      format, one more template variant, one more validation rule.

What disqualifies a candidate, no matter how small it looks:

  [ ] It needs a design decision you have not made. That is a discussion, not a task.
  [ ] Only you can verify it is correct.
  [ ] It touches more than about three files.
  [ ] You would be annoyed by any reasonable implementation other than your own.

Each issue you file needs, or it is not a good first issue:

  [ ] The file and roughly the lines involved.
  [ ] What "done" looks like, concretely enough to self-check.
  [ ] The command that verifies it.
  [ ] An explicit offer to answer questions, and a real response time you can honor.

Then:

  [ ] Apply BOTH "good first issue" and "help wanted". The first is GitHub's discovery
      surface; the second signals you actually want the help.
  [ ] Add "mentor available" to the two you would most enjoy walking someone through.
  [ ] Do not assign them to yourself, and do not fix them while waiting. A stale, done
      issue with the label still on it is the fastest way to burn a first-time
      contributor's evening.

CHECKLIST
}

if [ "$SEED_ONLY" = true ]; then
  print_seed_checklist
  exit 0
fi

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not found. Install from https://cli.github.com" >&2
  exit 1
fi

if [ -n "$TARGET" ]; then
  REPO_FLAG=(--repo "$TARGET")
  echo "Setting up labels for: $TARGET"
else
  REPO_FLAG=()
  echo "Setting up labels for current repo..."
fi

create_label() {
  local name="$1" color="$2" description="$3"
  if gh label list "${REPO_FLAG[@]}" --json name --jq '.[].name' 2>/dev/null | grep -qx "$name"; then
    echo "  → skipped (exists): $name"
  else
    gh label create "$name" --color "$color" --description "$description" "${REPO_FLAG[@]}"
    echo "  ✓ created: $name"
  fi
}

echo ""
echo "── Core Labels ──"
create_label "bug"              "d73a4a" "Something isn't working"
create_label "enhancement"     "a2eeef" "New feature or request"
create_label "documentation"   "0075ca" "Improvements or additions to documentation"
create_label "question"        "d876e3" "Further information is requested"
create_label "duplicate"       "cfd3d7" "This issue or PR already exists"
create_label "wontfix"         "ffffff" "This will not be worked on"
create_label "invalid"         "e4e669" "This doesn't seem right"

echo ""
echo "── Contributor Labels ──"
create_label "good first issue" "7057ff" "Good for newcomers, scoped and documented"
create_label "help wanted"      "008672" "Extra attention is needed, community contributions welcome"
create_label "mentor available" "0052cc" "Maintainer will mentor implementation"

echo ""
echo "── Priority Labels ──"
create_label "priority: high"   "b60205" "Needs to be addressed soon"
create_label "priority: medium" "fbca04" "Important but not urgent"
create_label "priority: low"    "0e8a16" "Nice to have"

echo ""
echo "── Type Labels ──"
create_label "breaking change" "e11d48" "Changes that break existing functionality"
create_label "security"        "b60205" "Security vulnerability or concern"
create_label "performance"     "0052cc" "Performance improvement"
create_label "dependencies"    "0075ca" "Pull requests that update a dependency"

# Referenced by templates/.github/labeler.yml and stale.yml. Without these, the
# generated automation creates them ad hoc with a random colour on first use.
echo ""
echo "── Automation Labels ──"
create_label "tests"           "bfd4f2" "Test coverage or test infrastructure"
create_label "ci"              "bfd4f2" "CI/CD workflows and automation"
create_label "stale"           "cfd3d7" "No activity for a long time, applied by the stale workflow"
create_label "pinned"          "0e8a16" "Exempt from the stale workflow"

echo ""
echo "Done. All standard OSS labels configured."
echo ""
echo "Next: seed 3-5 real \"good first issue\" entries."
echo "      bash scripts/setup-labels.sh --good-first-issue-seed"
