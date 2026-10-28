#!/usr/bin/env bash
# A rolling warning issue for a failed calendar refresh; successful recovery closes it.
# Environment: GH_TOKEN, SUCCESS=true|false, RUN_URL.
set -euo pipefail

label=calendar-refresh
mention=@economic/realtalk-maintainers
issue=$(gh issue list --label "$label" --state open --json number --jq '.[0].number // empty')

if [ "$SUCCESS" = true ]; then
  if [ -n "$issue" ]; then
    gh issue close "$issue" --comment "The release calendar was refreshed successfully: $RUN_URL"
  fi
  exit 0
fi

body=$(mktemp)
trap 'rm -f "$body"' EXIT
{
  echo "$mention"
  echo
  echo "Calendar refresh failed: $RUN_URL"
  echo
  echo 'The previously saved schedule remains in use. Check the failed run, then rerun Calendar refresh. Draft update is available manually.'
} > "$body"

if [ -z "$issue" ]; then
  gh label create "$label" --color FBCA04 --description "Release calendar refresh needs attention" --force > /dev/null
  gh issue create --title "Release calendar refresh failed" --label "$label" --body-file "$body"
else
  gh issue comment "$issue" --body-file "$body"
fi
