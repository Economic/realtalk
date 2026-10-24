#!/usr/bin/env bash
# Opens, updates, or closes the one new-data reminder issue. Run by the issue
# job of .github/workflows/new-data-check.yml, which runs no R.
#
# - new data, no open issue: open one that mentions the maintainers
# - new data, issue open: if it differs from the last notice, update the issue
#   and comment, which notifies; otherwise stay silent
# - no new data (the open draft or main has it): close any open issue
#
# Environment: GH_TOKEN, CHANGED ("true" or "false"), TITLE, BODY, HASH (a
# fingerprint of the fresh snapshots).
set -euo pipefail

label="new-data"
mention="@economic/realtalk-maintainers"

issue=$(gh issue list --label "$label" --state open --json number --jq '.[0].number // empty')

if [ "$CHANGED" != "true" ]; then
  if [ -n "$issue" ]; then
    gh issue close "$issue" --comment "The newest data is in the open draft or on \`main\`."
    echo "Closed #$issue: nothing left to draft."
  else
    echo "No new data, and no open reminder."
  fi
  exit 0
fi

# The fingerprint, hidden in the body, records what the last notice reported
marker="<!-- new-data-hash: $HASH -->"
body=$(mktemp)
{
  echo "$mention"
  echo
  printf '%s\n' "$BODY"
  echo
  echo "$marker"
} > "$body"

if [ -z "$issue" ]; then
  gh label create "$label" --color FBCA04 --description "New BLS or BEA data to draft" --force > /dev/null
  gh issue create --title "$TITLE" --label "$label" --body-file "$body"
elif gh issue view "$issue" --json body --jq .body | grep -qF "$marker"; then
  echo "Nothing new since the last notice on #$issue."
else
  gh issue edit "$issue" --title "$TITLE" --body-file "$body"
  gh issue comment "$issue" --body "$mention More new data: $TITLE."
  echo "Updated #$issue."
fi
