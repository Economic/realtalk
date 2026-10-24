#!/usr/bin/env bash
# The checks of "Publish update", before anything is merged. Run by the plan job
# of .github/workflows/publish-update.yml, in a checkout of main with full
# history and tags.
#
# Environment: GH_TOKEN, ACTOR (who pressed the button). Writes pr, head, and
# version to $GITHUB_OUTPUT.
set -euo pipefail
# shellcheck source=release-guards.sh
source "$(dirname "$0")/release-guards.sh"

branch="data-update"

require_maintainer "$ACTOR"

pr=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number // empty')
[ -n "$pr" ] || fail "There is no open $branch PR. Run \"Draft update\" first."
head=$(gh pr view "$pr" --json headRefOid --jq .headRefOid)

check=$(gh api "repos/$GITHUB_REPOSITORY/commits/$head/check-runs?check_name=check" \
  --jq '[.check_runs[] | select(.app.slug == "github-actions")] | sort_by(.started_at) | last | .conclusion // "missing"')
if [ "$check" != "success" ]; then
  fail "The check on the draft's latest commit is \"$check\". Click \"Approve and run workflows\" on the PR, and wait for the check to pass."
fi

# GitHub's review decision follows the ruleset: a code owner's approval of the
# latest commit
decision=$(gh pr view "$pr" --json reviewDecision --jq .reviewDecision)
[ "$decision" = "APPROVED" ] || fail "No maintainer has approved the draft's latest commit."

# The draft must be one commit by the bot directly on top of the current main.
# That also means main hasn't moved since the draft was built.
git fetch --quiet origin "$branch"
if [ "$(git rev-parse "$head^")" != "$(git rev-parse origin/main)" ]; then
  fail "main has changed since the draft was built, or someone pushed to $branch by hand. Run \"Draft update\" again."
fi
author=$(git log -1 --format=%an "$head")
[ "$author" = "github-actions[bot]" ] || fail "The draft's commit is by $author, not github-actions[bot]. Run \"Draft update\" again."

version=$(git show "$head:DESCRIPTION" | sed -n 's/^Version: *//p')
require_new_version "$head" "$version"

{
  echo "pr=$pr"
  echo "head=$head"
  echo "version=$version"
} >> "$GITHUB_OUTPUT"
echo "Ready to publish v$version from PR #$pr (${head:0:7})."
