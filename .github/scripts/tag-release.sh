#!/usr/bin/env bash
# Tags a commit on main and creates its GitHub release, which publishes it:
# r-universe builds the latest release. Shared by the tag jobs of
# .github/workflows/publish-update.yml and tag-release.yml, in a checkout with
# full history. Each step checks what already exists, so a rerun is safe.
#
# Environment: TARGET (the commit to release), GH_TOKEN, DRY_RUN ("true" or
# "false"). Writes tag and version to $GITHUB_OUTPUT.
set -euo pipefail

fail() {
  echo "::error::$1"
  exit 1
}

[[ "$TARGET" =~ ^[0-9a-f]{40}$ ]] || fail "TARGET must be a full commit SHA."

version=$(git show "$TARGET:DESCRIPTION" | sed -n 's/^Version: *//p')
[ -n "$version" ] || fail "No version in DESCRIPTION at $TARGET."
tag="v$version"

# The notes: the memo when the target merged the data-update PR, otherwise the
# version's NEWS.md entry
notes=$(mktemp)
memo_pr_body=$(gh api "repos/$GITHUB_REPOSITORY/commits/$TARGET/pulls" \
  --jq '[.[] | select(.head.ref == "data-update" and .merge_commit_sha == "'"$TARGET"'")][0].body // empty')
if [ -n "$memo_pr_body" ]; then
  printf '%s\n' "$memo_pr_body" | sed -n '/^## Data update memo/,$p' > "$notes"
else
  git show "$TARGET:NEWS.md" |
    awk -v heading="## Version $version" '$0 == heading {found = 1; next} found && /^## /{exit} found' > "$notes"
fi
[ -s "$notes" ] || fail "No release notes for $version: no memo, and no NEWS.md entry."

if [ "$DRY_RUN" = "true" ]; then
  {
    echo "## Dry run: would release $tag on ${TARGET:0:7}"
    echo
    cat "$notes"
  } >> "$GITHUB_STEP_SUMMARY"
  echo "Dry run: would release $tag on ${TARGET:0:7}."
else
  # The tag, through the API, on the target commit
  # gh writes the error JSON to stdout for a missing tag; discard it on failure.
  existing=$(gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$tag" --jq .object.sha 2>/dev/null) || existing=""
  if [ -z "$existing" ]; then
    gh api "repos/$GITHUB_REPOSITORY/git/refs" -f ref="refs/tags/$tag" -f sha="$TARGET" > /dev/null
    echo "Created the tag $tag on ${TARGET:0:7}."
  elif [ "$existing" != "$TARGET" ]; then
    fail "The tag $tag already points at ${existing:0:7}, not ${TARGET:0:7}. Check it on the tags page."
  else
    echo "The tag $tag already points at ${TARGET:0:7}."
  fi

  # The release, checked separately from the tag
  if gh release view "$tag" > /dev/null 2>&1; then
    echo "The release $tag already exists."
  else
    gh release create "$tag" --verify-tag --title "Version $version" --notes-file "$notes" --latest
    echo "Published $tag: https://github.com/$GITHUB_REPOSITORY/releases/tag/$tag"
  fi
fi

{
  echo "tag=$tag"
  echo "version=$version"
} >> "$GITHUB_OUTPUT"
