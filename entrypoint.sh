#!/bin/bash

# validate subscription status
UPSTREAM="reviewdog/action-misspell"
ACTION_REPO="${GITHUB_ACTION_REPOSITORY:-}"
DOCS_URL="https://docs.stepsecurity.io/actions/stepsecurity-maintained-actions"

echo ""
echo -e "\033[1;36mStepSecurity Maintained Action\033[0m"
echo "Secure drop-in replacement for $UPSTREAM"
if [ "$REPO_PRIVATE" = "false" ]; then
  echo -e "\033[32m✓ Free for public repositories\033[0m"
fi
echo -e "\033[36mLearn more:\033[0m $DOCS_URL"
echo ""

if [ "$REPO_PRIVATE" != "false" ]; then
  SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"

  if [ "$SERVER_URL" != "https://github.com" ]; then
    BODY=$(printf '{"action":"%s","ghes_server":"%s"}' "$ACTION_REPO" "$SERVER_URL")
  else
    BODY=$(printf '{"action":"%s"}' "$ACTION_REPO")
  fi

  API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/maintained-actions-subscription"

  RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "$API_URL" -o /dev/null) && CURL_EXIT_CODE=0 || CURL_EXIT_CODE=$?

  if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Timeout or API not reachable. Continuing to next step."
  elif [ "$RESPONSE" = "403" ]; then
    echo -e "::error::\033[1;31mThis action requires a StepSecurity subscription for private repositories.\033[0m"
    echo -e "::error::\033[31mLearn how to enable a subscription: $DOCS_URL\033[0m"
    exit 1
  fi
fi

cd "${GITHUB_WORKSPACE}" || exit 1

git config --global --add safe.directory $GITHUB_WORKSPACE || exit 1

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

paths=()
while read -r pattern; do
    [[ -n ${pattern} ]] && paths+=("${pattern}")
done <<< "${INPUT_PATH:-.}"

names=()
if [[ "${INPUT_PATTERN:-*}" != '*' ]]; then
    while read -r pattern; do
        [[ -n ${pattern} ]] && names+=(-o -name "${pattern}")
    done <<< "${INPUT_PATTERN}"
    (( ${#names[@]} )) && { names[0]='('; names+=(')'); }
fi

excludes=()
while read -r pattern; do
    [[ -n ${pattern} ]] && excludes+=(-not -path "${pattern}")
done <<< "${INPUT_EXCLUDE:-}"

find "${paths[@]}" "${excludes[@]}" -type f "${names[@]}" -print0 \
    | xargs -0 misspell -locale="${INPUT_LOCALE}" -i "${INPUT_IGNORE}" \
    | reviewdog -efm="%f:%l:%c: %m" \
        -filter-mode="${INPUT_FILTER_MODE:-added}" \
        -name="misspell" \
        -reporter="${INPUT_REPORTER:-github-pr-check}" \
        -level="${INPUT_LEVEL}" \
        -fail-level="${INPUT_FAIL_LEVEL}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}"
exit_code=$?

exit $exit_code
