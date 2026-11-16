# Maintaining realtalk

1. Open the automatic data update PR. To create one manually, run **Actions → Draft update** on `main`.
2. Click **Approve and run workflows** if asked. Wait for passing checks.
3. Read the memo. If correct, select **Files changed → Review changes → Approve**.
4. Run **Actions → Publish update** on `main`. Wait for it to finish.

## Review and publish

Check the memo's data coverage, revisions, unexpected revisions, FRED comparison,
and stale inputs. Investigate anything unexpected before approving.

The `realtalk-maintainers` team approves PRs and runs releases. Anyone with
Write access can draft updates and start PR checks. Authors cannot approve
their own PRs.

**Publish update** merges the data PR, checks the merge commit, and creates a
release. The release publishes to r-universe and updates the website. Merging
alone publishes nothing. Do not create releases by hand; that skips checks.

The workflow asks r-universe to sync. Allow about 10 to 15 minutes.

## How data drafts work

- **Calendar refresh:** Mondays, 5:17 a.m. Eastern. Saves BLS and BEA release
  dates on the `calendar` branch.
- **Scheduled data update:** daily, 10:17 a.m. Eastern. Drafts on release days
  and rebuilds open drafts after `main` changes. GitHub can start runs late.
- **Draft update:** fetches data, compares with FRED, sets the version and
  `NEWS.md`, checks the package, and updates the `data-update` PR. If data
  matches `main`, it closes any old data PR.

Automatic runs keep approval if processed data and the base commit are unchanged.
Manual drafts always replace the draft and remove approval.

Do not edit `data-update` by hand. Merge fixes through a separate PR to `main`,
then run **Draft update** again.

Versions use the draft date in Eastern time, `YYYY.M.D`, plus `.1`, `.2`, etc.
if needed.

**New data check** manually checks for newer data and manages the `new-data`
reminder issue. Merging the data PR also closes the reminder.

For previews, select `dry_run` in **Draft update**, **Calendar refresh**,
**Scheduled data update**, or either release workflow. This leaves branches,
issues, and releases unchanged. Real runs use `main`.

## Other changes

Use an ordinary PR for code fixes and hand-maintained data in
`data-raw/raw/static/` (CPI-U-RS, CPI-U-X1, and the minimum wage).

1. Make the change on a branch and rebuild the affected outputs. To publish it,
   update `Version` in `DESCRIPTION` and add a `NEWS.md` entry.
2. Get maintainer approval and passing checks. Merge with a merge commit.
3. To publish, run **Actions → Tag release** on `main`. It checks and releases
   the current `main` by default.

Admins can merge their own PR without another approval, but the required check
must pass.

## If an update fails

| Problem | Action |
|---|---|
| Calendar or schedule fails | Rerun **Calendar refresh**, or use **Draft update** manually. Failed refreshes notify maintainers and keep the old schedule. |
| Download fails or expected data is missing | Retry **Draft update** later. Old source data can produce no PR or notification. There is no automatic retry. |
| FRED comparison fails | Investigate the named series and month. |
| Publish update refuses | Follow the error. If `main` changed, draft again and review again. |
| Publish update fails after merging | Select **Re-run failed jobs**. Alternatively, run **Tag release** with the merge commit from the failed run's summary. |
| r-universe sync warns or times out | The release exists. Try the [sync button](https://economic.r-universe.dev/packages) or inspect [builds](https://github.com/r-universe/economic/actions). |

If the sync request fails, r-universe can take a few hours to find the release.

## Setup and settings

- **Secrets:** set `BLS_API_KEY`, `BEA_API_KEY`, `FRED_API_KEY`, and
  `BLS_DOWNLOAD_EMAIL` in repository settings. The email is the BLS calendar
  download contact. Local calendar refreshes need the same environment variable.
- **First calendar run:** run **Calendar refresh** with `dry_run`, check the
  dates in the summary, then run it without `dry_run`. Keep the `calendar`
  branch. Run Calendar refresh manually if an agency changes a date before the
  next Monday.
- **Code owners:** `.github/CODEOWNERS` must name
  `@economic/realtalk-maintainers`. The team must be visible and have Maintain
  access.
- **Rulesets** (Settings → Rules): “protect main” requires a PR, one code-owner
  approval, dismissal of approvals after new commits, and merge commits only.
  It blocks force pushes and deletion; admins can bypass it for PRs.
  “require check on main” requires `check` to pass, with no bypass.
- **r-universe:** keep `"branch": "*release"` for realtalk in
  `economic/economic.r-universe.dev`'s `packages.json`.
