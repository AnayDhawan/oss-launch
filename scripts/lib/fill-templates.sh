#!/usr/bin/env bash
# fill-templates.sh — shared placeholder-substitution engine.
# Caller sets the token variables (OWNER, REPO, AUTHOR, ...) before calling fill().
# Token list must stay in sync with references/generate.md's Placeholder map.
# Sourced, not executed directly.

default_var() {  # default_var VAR_NAME "fallback value" -- sets VAR_NAME only if unset/empty
  local name="$1" fallback="$2"
  if [ -z "${!name:-}" ]; then
    printf -v "$name" '%s' "$fallback"
  fi
}

fill() {  # fill <file> -- substitute every known {{TOKEN}} in place
  sed -i \
    -e "s/{{OWNER}}/$OWNER/g" -e "s/{{REPO}}/$REPO/g" \
    -e "s/{{AUTHOR}}/$AUTHOR/g" -e "s/{{YEAR}}/$YEAR/g" \
    -e "s/{{LICENSE}}/$LICENSE/g" \
    -e "s#{{TAGLINE}}#$TAGLINE#g" -e "s/{{STACK}}/$STACK/g" \
    -e "s/{{ECOSYSTEM}}/$ECOSYSTEM/g" -e "s/{{TEST_COMMAND}}/$TEST_COMMAND/g" \
    -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    -e "s#{{INSTALL_COMMAND}}#$INSTALL_COMMAND#g" \
    -e "s#{{COPY_ENV_COMMAND}}#$COPY_ENV_COMMAND#g" \
    -e "s#{{DEV_START_COMMAND}}#$DEV_START_COMMAND#g" \
    -e "s#{{SETUP_NOTES}}#$SETUP_NOTES#g" \
    -e "s#{{VERIFY_COMMAND}}#$VERIFY_COMMAND#g" \
    -e "s#{{GOOD_FIRST_ISSUES_LIST}}#$GOOD_FIRST_ISSUES_LIST#g" \
    -e "s#{{STYLE_RULE_1}}#$STYLE_RULE_1#g" \
    -e "s#{{STYLE_RULE_2}}#$STYLE_RULE_2#g" \
    -e "s#{{STYLE_RULE_3}}#$STYLE_RULE_3#g" \
    -e "s#{{PROJECT_SPECIFIC_PR_RULE}}#$PROJECT_SPECIFIC_PR_RULE#g" \
    -e "s#{{COMMUNITY_LINK}}#$COMMUNITY_LINK#g" \
    -e "s/{{CURRENT_MAJOR}}/$CURRENT_MAJOR/g" \
    -e "s/{{SECURITY_EMAIL}}/$SECURITY_EMAIL/g" \
    -e "s/{{CONTACT_EMAIL}}/$CONTACT_EMAIL/g" \
    -e "s/{{INITIAL_VERSION}}/$INITIAL_VERSION/g" \
    -e "s/{{RELEASE_DATE}}/$RELEASE_DATE/g" \
    -e "s#{{INITIAL_FEATURE_1}}#$INITIAL_FEATURE_1#g" \
    -e "s#{{INITIAL_FEATURE_2}}#$INITIAL_FEATURE_2#g" \
    "$1"
}
