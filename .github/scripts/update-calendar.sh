#!/usr/bin/env bash
# Save the validated calendar artifact in an isolated checkout of calendar.
# Never check out calendar over the scripts/code running this workflow.
set -euo pipefail

schedule=$(realpath "${1:?Usage: update-calendar.sh schedule.json}")
[ -f "$schedule" ] && [ ! -L "$1" ] || { echo "Expected a regular schedule.json file" >&2; exit 1; }
remote=$(git remote get-url origin)
calendar_repo=$(mktemp -d)
trap 'rm -rf "$calendar_repo"' EXIT

gh auth setup-git
git init --quiet "$calendar_repo"
git -C "$calendar_repo" remote add origin "$remote"

if git -C "$calendar_repo" ls-remote --exit-code --heads origin refs/heads/calendar > /dev/null; then
  git -C "$calendar_repo" fetch --quiet --depth=1 origin calendar
  git -C "$calendar_repo" checkout --quiet -b calendar FETCH_HEAD
else
  status=$?
  [ "$status" = 2 ] || exit "$status"
  git -C "$calendar_repo" checkout --quiet --orphan calendar
fi

cp "$schedule" "$calendar_repo/schedule.json"
git -C "$calendar_repo" add schedule.json
if git -C "$calendar_repo" diff --cached --quiet; then
  echo "The saved calendar is unchanged."
  exit 0
fi

GIT_AUTHOR_NAME='github-actions[bot]' \
GIT_AUTHOR_EMAIL='41898282+github-actions[bot]@users.noreply.github.com' \
GIT_COMMITTER_NAME='github-actions[bot]' \
GIT_COMMITTER_EMAIL='41898282+github-actions[bot]@users.noreply.github.com' \
  git -C "$calendar_repo" commit --quiet -m "Refresh BLS and BEA release calendar"
git -C "$calendar_repo" push --quiet origin HEAD:refs/heads/calendar
echo "Saved the release schedule on calendar."
