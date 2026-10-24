#!/usr/bin/env bash
# Checks shared by publish-plan.sh and tag-release-plan.sh. Sourced, not run.
# They need GH_TOKEN, GITHUB_REPOSITORY, and a checkout with full history and
# tags.

fail() {
  echo "::error::$1"
  exit 1
}

# Only realtalk-maintainers (the Maintain role) and admins may publish
require_maintainer() {
  local actor="$1" role
  role=$(gh api "repos/$GITHUB_REPOSITORY/collaborators/$actor/permission" --jq .role_name)
  case "$role" in
    admin | maintain) ;;
    *) fail "Only realtalk-maintainers can publish; $actor has the $role role." ;;
  esac
}

# The version must be unreleased, higher than the latest release, and have a
# NEWS.md entry at the commit
require_new_version() {
  local commit="$1" version="$2" latest highest
  if gh release view "v$version" > /dev/null 2>&1; then
    fail "v$version is already released."
  fi
  latest=$(gh release view --json tagName --jq .tagName)
  # sort -V also orders the older zero-padded tags, such as v2026.02.13
  highest=$(printf '%s\n%s\n' "${latest#v}" "$version" | sort -V | tail -n 1)
  if [ "$highest" != "$version" ] || [ "${latest#v}" = "$version" ]; then
    fail "Version $version isn't higher than the latest release, $latest."
  fi
  if ! git show "$commit:NEWS.md" | grep -qx "## Version $version"; then
    fail "NEWS.md has no entry for $version."
  fi
}
