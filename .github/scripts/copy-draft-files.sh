#!/usr/bin/env bash
# Copies the build job's files from the unpacked artifact into the checkout.
# Run by the PR job of .github/workflows/draft-update.yml, adapted from
# productivity_pay_gap's copy-refresh-files.sh.
#
# The build job ran package code, so the artifact could hold anything. Only
# regular files at the expected paths are copied. Unpacked straight over the
# checkout, a file such as .git/config could run commands in later git calls,
# with the write token present.
set -euo pipefail

artifact="$1"
allowed='^data/[A-Za-z0-9_]+\.rda$|^data-raw/processed/[A-Za-z0-9_]+\.csv$|^data-raw/raw/snapshots/[A-Za-z0-9_]+\.csv$|^DESCRIPTION$|^NEWS\.md$|^README\.md$|^man/figures/README-[A-Za-z0-9_-]+\.png$|^reports/change_memo\.md$'

cd "$artifact"

# no symlinks, devices or other special files
if [ -n "$(find . ! -type d ! -type f -print -quit)" ]; then
  echo "::error::The artifact contains something other than regular files."
  exit 1
fi

files=()
while IFS= read -r -d '' path; do
  path="${path#./}"
  if ! [[ "$path" =~ $allowed ]]; then
    # %q escapes the name, so it can't inject workflow commands into the log
    printf '::error::Unexpected file in the artifact: %q\n' "$path"
    exit 1
  fi
  files+=("$path")
done < <(find . -type f -print0)

for path in "${files[@]}"; do
  mkdir -p "$GITHUB_WORKSPACE/$(dirname "$path")"
  cp "$path" "$GITHUB_WORKSPACE/$path"
done
echo "Copied ${#files[@]} files."
