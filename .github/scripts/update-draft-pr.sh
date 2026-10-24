#!/usr/bin/env bash
# Opens, updates, or closes the draft PR on the `data-update` branch. Run by the
# PR job of .github/workflows/draft-update.yml, in a checkout of the build's
# commit with the build's files copied on top.
#
# One decision, comparing the fresh processed data with main's:
# - the same: main already has this data, so close any open draft, and stop
# - different: force-push a new draft and open or update the PR. This happens
#   even if the data equals the open draft's; the push cancels any approval.
#
# Environment: GH_TOKEN, ACTOR (who pressed the button), RUN_URL.
set -euo pipefail

branch="data-update"
memo="reports/change_memo.md"

pr=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number // empty')

if git diff --quiet origin/main -- data-raw/processed; then
  if [ -n "$pr" ]; then
    gh pr close "$pr" --delete-branch --comment "\`main\` already has these numbers."
    echo "Closed the draft PR #$pr: main already has this data."
  else
    echo "No new data: the fresh data matches main."
  fi
  exit 0
fi

version=$(sed -n 's/^Version: *//p' DESCRIPTION)
# The memo's headline is its first bold line
headline=$(sed -n 's/^\*\*\(.*\)\*\*$/\1/p' "$memo" | head -n 1)
title="Data update $version: $headline"

# The draft branch: exactly one commit by the bot on top of the build's commit
git switch --quiet -C "$branch"
git add -A data data-raw/processed data-raw/raw/snapshots DESCRIPTION NEWS.md README.md man/figures
# Set through the environment, which overrides any git config: "Publish update"
# checks this author
bot="github-actions[bot]"
bot_email="41898282+github-actions[bot]@users.noreply.github.com"
GIT_AUTHOR_NAME="$bot" GIT_AUTHOR_EMAIL="$bot_email" \
  GIT_COMMITTER_NAME="$bot" GIT_COMMITTER_EMAIL="$bot_email" \
  git commit --quiet -m "$title"
gh auth setup-git
git push --quiet --force origin "$branch"

body=$(mktemp)
{
  echo "Drafted by $ACTOR ([run]($RUN_URL)). Merging publishes nothing; a maintainer publishes with \"Publish update\"."
  echo
  echo "To publish: click \"Approve and run workflows\" so the check runs, have a maintainer approve the PR, then run \"Publish update\"."
  echo
  cat "$memo"
  echo
  echo "### Checks"
  echo
  echo "In the build: FRED verification, R CMD check (with the consistency tests), and the pipeline tests all passed."
} > "$body"

if [ -z "$pr" ]; then
  gh pr create --base main --head "$branch" --title "$title" \
    --body-file "$body" --assignee "$ACTOR"
else
  gh pr edit "$pr" --title "$title" --body-file "$body" --add-assignee "$ACTOR"
  # the comment notifies people following the PR that the draft changed
  gh pr comment "$pr" --body "Redrafted by $ACTOR ([run]($RUN_URL)): $headline. Any approval was cancelled."
fi
