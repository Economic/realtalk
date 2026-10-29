# Maintaining realtalk

## How publishing works

- **A GitHub release publishes.** r-universe builds the latest GitHub
  release of realtalk, not `main`. Merging to `main` publishes nothing,
  so `main` can be ahead of what users install.
- **Releases come only from two buttons:** “Publish update”, for data
  updates, and “Tag release”, for everything else. Don’t create releases
  by hand from the Releases page; nothing enforces this, but a hand-made
  release skips every check.
- **The pkgdown site** deploys from each release’s tag, so it matches
  what r-universe serves.

## Who does what

- **Drafters:** automation prepares data PRs on release days. Anyone
  with Write access can also press “Draft update” and start the checks
  on its PR.
- **Maintainers:** the `realtalk-maintainers` team, with the Maintain
  role. Only their approval lets a PR merge, and only they can press
  “Publish update” and “Tag release”.

## A data update

Every Monday at **5:17 a.m. Eastern**, **Calendar refresh** downloads
the BLS and BEA calendars and saves upcoming CPI, Personal Income and
Outlays, and GDP release times in `schedule.json` on the separate
`calendar` branch. It replaces that file only after both calendars have
been read and validated. A failed refresh notifies maintainers and keeps
the previous schedule.

Every day at **10:17 a.m. Eastern**, **Scheduled data update** reads
that saved schedule. On release days it runs **Draft update**, which
fetches all sources, builds and checks the package, then opens or
refreshes the data PR. It also rebuilds an existing data PR if `main`
changed since that draft was built. Times follow Eastern daylight saving
changes; GitHub may start a scheduled run late.

An automatic run leaves an existing PR and its approval alone when its
processed data and base commit are unchanged. New values or a changed
base require a new draft and review. Publishing always requires a
maintainer. The manual path remains available:

| \# | Who | Where | What happens |
|----|----|----|----|
| 1 | Automation, or anyone with Write access | Actions → **Draft update** → Run workflow | Fetches the data, rebuilds, checks it against FRED, sets the version and the `NEWS.md` entry, runs R CMD check, and opens a PR from the `data-update` branch with a memo of what changed. Nothing is published. If the data matches `main`, it stops and closes any old data PR. |
| 2 | Anyone with Write access | The PR → **Approve and run workflows** | Starts the PR’s checks, which GitHub holds because a bot opened the PR. |
| 3 | A maintainer | The PR → Files changed → **Review changes** → **Approve** | The sign-off. Read the memo first: coverage, revisions, unexpected revisions, the FRED comparison, and stale inputs. |
| 4 | A maintainer | Actions → **Publish update** → Run workflow | Merges the PR, checks the merge commit, tags it, and creates the release, which publishes. Then it deploys the site and waits for r-universe to serve the new version. |

**New data check** remains available as a manual diagnostic: it compares
fresh snapshots with the open draft or `main` and manages the `new-data`
reminder issue. If a reminder issue is open, the draft PR’s description
says `Closes #N`, so publishing the draft closes the issue. Running New
data check also closes a reminder once the draft or `main` contains the
newest data.

**Notes:**

- **The version** is the draft’s date in Eastern time, for example
  `2026.11.13`, with a suffix such as `2026.11.13.1` if that version is
  already released.
- **Pressing “Draft update” again** deliberately replaces the draft and
  cancels any approval, even if its data is unchanged. Use this to retry
  or rebuild immediately after a code fix reaches `main`. Automatic runs
  skip that replacement when both data and base commit are unchanged.
- **Don’t push to `data-update` by hand.** “Publish update” refuses a
  draft that isn’t one commit by the bot. Fix problems in their own PR
  to `main`, then draft again.
- **Dry runs:** Calendar refresh, Scheduled data update, Draft update,
  Publish update, and Tag release have a `dry_run` box that reports the
  result without changing branches, issues, or releases. Dry runs can
  test calendar and drafting changes from a branch; real calendar and
  scheduled draft runs use `main`.

## Starting and repairing the calendar schedule

Set the repository secret `BLS_DOWNLOAD_EMAIL` to a contact email before
running Calendar refresh. The BLS calendar request uses
`User-Agent: realtalk calendar <email>`; local refreshes need the same
environment variable.

After first merging these workflows, run **Calendar refresh** with
`dry_run` checked, inspect the saved dates in its summary, then run it
without `dry_run` to create the `calendar` branch. The daily job needs
that first saved schedule. Keep the branch: it is the persistent copy
used when a later calendar download fails.

Calendar changes announced after Monday are picked up on the following
Monday. A release changing within its own week is an accepted risk; run
Calendar refresh manually when necessary. If an agency API or FRED is
not ready at 10:17, retry with Draft update. There is no automatic retry
schedule.

Rarely, an agency API may still return old data at 10:17. That run can
succeed without creating or changing a draft, and it sends no additional
notification. This is an accepted risk; use Draft update manually if the
expected data is missing.

## Other changes

Code fixes and updates to the hand-maintained files in
`data-raw/raw/static/` (CPI-U-RS, CPI-U-X1, the minimum wage) go through
an ordinary PR:

1.  Make the change on a branch, rebuild what it affects, and open a PR.
    To publish it, bump `Version` in `DESCRIPTION` (the scheme is
    `YYYY.M.D`) and add a `NEWS.md` entry.
2.  A maintainer approves, and the PR is merged with GitHub’s merge
    button. This publishes nothing.
3.  A maintainer runs Actions → **Tag release**. It checks the commit
    and version, runs the checks, then tags and releases the current
    `main`.

GitHub doesn’t count a PR author’s own approval, so maintainers approve
each other’s PRs. As a backup, admins can merge their own PR without an
approval, but never without a passing check.

## When something fails

- **“Calendar refresh” fails:** maintainers are notified and the
  previous saved schedule remains available. Inspect the failed run,
  then rerun Calendar refresh. The daily job continues using the old
  dates.
- **“Scheduled data update” has no usable schedule:** bootstrap or rerun
  Calendar refresh. A missing, malformed, or exhausted calendar reports
  a failure. Draft update remains available manually.
- **“Draft update” fails at the fetch:** BLS or BEA sometimes refuses a
  request for a moment. BEA’s refusals currently show up as “Column
  `time_period` not found” (Economic/epidatatools#22). Run it again.
- **“Draft update” fails the FRED comparison:** a value differs from
  FRED. The error names the series and month. Investigate before
  drafting again.
- **“Publish update” refuses:** its message says why, for example no
  approval yet, the check hasn’t passed, or `main` changed since the
  draft (draft again).
- **“Publish update” fails after the merge:** the data is on `main` but
  not published until the release exists. In the failed run, click
  **Re-run failed jobs**. If that’s not possible, run **Tag release**
  with the merge commit shown in the failed run’s summary.
- **The r-universe wait fails after 3 hours:** the release exists but
  r-universe hasn’t built it. Check
  <https://github.com/r-universe/economic/actions>.
- **Slow runs:** setting up R on GitHub’s runners sometimes takes 15
  minutes or more. That’s GitHub, not realtalk.

## Settings

These live in GitHub, not in the repository:

- **Rulesets** (Settings → Rules):
  - **“protect main”**: pull requests required; one approval from a code
    owner; approvals dismissed by new commits; merge commits only; no
    force pushes or deletion. Admins can bypass it for pull requests.
  - **“require check on main”**: the `check` workflow must pass. Nobody
    can bypass it.
- **`.github/CODEOWNERS`** names `@economic/realtalk-maintainers`. The
  team must be visible and have the Maintain role on realtalk, or GitHub
  ignores the line.
- **Repository secrets:** `BLS_API_KEY`, `BEA_API_KEY`, `FRED_API_KEY`,
  and `BLS_DOWNLOAD_EMAIL` (calendar download contact email).
- **r-universe:** realtalk’s entry in
  `economic/economic.r-universe.dev`’s `packages.json` has
  `"branch": "*release"`.
