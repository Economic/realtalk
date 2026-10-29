#!/usr/bin/env bash
# The checks of "Tag release". Run by its plan job, in a checkout of main with
# full history and tags.
#
# Environment: GH_TOKEN, ACTOR (who pressed the button), COMMIT (optional; the
# current main if empty). Writes target and version to $GITHUB_OUTPUT.
set -euo pipefail
# shellcheck source=release-guards.sh
source "$(dirname "$0")/release-guards.sh"

require_maintainer "$ACTOR"

if [ -n "${COMMIT:-}" ]; then
  [[ "$COMMIT" =~ ^[0-9a-f]{7,40}$ ]] || fail "The commit must be a commit SHA."
  target=$(git rev-parse --verify --quiet "$COMMIT^{commit}") || fail "There is no commit $COMMIT."
else
  target=$(git rev-parse origin/main)
fi

# Every change reaches main as a merge, so a commit to release must be on
# main's first-parent history, never a commit inside a PR. Read all of git's
# output: grep -q can close the pipe early and make git fail under pipefail.
git rev-list --first-parent origin/main | grep -x "$target" > /dev/null ||
  fail "${target:0:7} isn't on main's first-parent history."

version=$(git show "$target:DESCRIPTION" | sed -n 's/^Version: *//p')
require_new_version "$target" "$version"

{
  echo "target=$target"
  echo "version=$version"
} >> "$GITHUB_OUTPUT"
echo "Ready to release v$version on ${target:0:7}."
