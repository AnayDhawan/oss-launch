#!/usr/bin/env bash
# fill-templates.sh: shared placeholder-substitution engine.
# Caller sets the token variables (OWNER, REPO, AUTHOR, ...) before calling fill().
# Token list must stay in sync with references/generate.md's Placeholder map.
# Sourced, not executed directly.

default_var() {  # default_var VAR_NAME "fallback value" -- sets VAR_NAME only if unset/empty
  local name="$1" fallback="$2"
  if [ -z "${!name:-}" ]; then
    printf -v "$name" '%s' "$fallback"
  fi
}

# Every token fill() knows how to substitute. A plain bash array, not a sed script,
# so a value containing "/", "#", "&", or any other sed-special character is just
# text: no delimiter to collide with, no "&" whole-match expansion to guard against.
_FILL_TOKENS=(
  OWNER REPO AUTHOR YEAR LICENSE TAGLINE STACK ECOSYSTEM TEST_COMMAND
  PROJECT_NAME INSTALL_COMMAND COPY_ENV_COMMAND DEV_START_COMMAND SETUP_NOTES
  VERIFY_COMMAND GOOD_FIRST_ISSUES_LIST STYLE_RULE_1 STYLE_RULE_2 STYLE_RULE_3
  PROJECT_SPECIFIC_PR_RULE COMMUNITY_LINK CURRENT_MAJOR SECURITY_EMAIL
  CONTACT_EMAIL INITIAL_VERSION RELEASE_DATE INITIAL_FEATURE_1 INITIAL_FEATURE_2
  SITE_URL DEFAULT_BRANCH
)

# _FILL_TOKENS is a single list, but the VALUES behind it are set by two independent
# callers: scripts/apply.sh for real runs, demo/scaffold.sh for the demo and CI's
# generation fixtures. Adding a token to the list and to only one of them used to ship a
# literal {{TOKEN}} into generated output, caught later (if at all) by
# check-placeholders.sh's second pass. This turns that silent drift into a loud failure
# at the caller, before anything is written.
require_all_tokens() {  # require_all_tokens <caller-label> -- non-zero if any token is unset
  local caller="$1" token
  local missing=()
  for token in "${_FILL_TOKENS[@]}"; do
    [ -z "${!token:-}" ] && missing+=("$token")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "$caller: no value set for fill() token(s): ${missing[*]}" >&2
    echo "Every token in _FILL_TOKENS (scripts/lib/fill-templates.sh) must be set by every caller of fill()." >&2
    return 1
  fi
  return 0
}

fill() {  # fill <file> -- substitute every known {{TOKEN}} in place
  local file="$1" content token value
  content="$(cat "$file"; printf x)"
  content="${content%x}"  # printf x/strip preserves a trailing newline $() would eat

  for token in "${_FILL_TOKENS[@]}"; do
    value="${!token:-}"
    # Both sides must be quoted: an unquoted replacement re-expands, and bash
    # reinserts a literal "&" in the pattern's place when it does (the exact
    # sed footgun this rewrite exists to remove, just moved, not fixed, by an
    # unquoted right-hand side).
    content="${content//"{{$token}}"/"$value"}"
  done

  printf '%s' "$content" > "$file"
}
