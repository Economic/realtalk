# Maintaining realtalk

1. Open the automatic data update PR. If needed, create one with **Actions → Draft update**.
2. Click **Approve and run workflows** if GitHub asks. Wait for passing checks.
3. Read the memo. Check new data, revisions, FRED results, and stale sources. Approve if correct.
4. Run **Actions → Publish update**. It merges the PR, checks it, and publishes the package and website.

For manual workflows, select `main`, then **Run workflow**. Only maintainers
can publish. Allow about 10 to 15 minutes for r-universe to update.

## Data updates

Drafts are created automatically on BLS and BEA release days. You can also run
**Draft update** yourself. It sets the version and release notes.

A manual draft removes the previous approval. Review and approve it again.
Do not edit the `data-update` branch. Merge fixes through a separate PR, then
draft again.

## Other changes

1. Open a PR. Rebuild affected outputs. If publishing, update `Version` in
   `DESCRIPTION` (`YYYY.M.D`) and add a `NEWS.md` entry.
2. Get approval and passing checks, then merge with a merge commit.
3. To publish, run **Actions → Tag release** on `main`.

Merging alone does not publish anything. Do not create releases by hand.
Admins can merge their own PRs, but checks must pass.

## Problems

- **Missing data or failed download:** retry **Draft update** later.
- **FRED mismatch or unexpected values:** investigate before approving.
- **Calendar failure:** run **Calendar refresh**, or draft manually.
- **Publish refused:** follow the error. If `main` changed, draft and review again.
- **Publish failed after merging:** select **Re-run failed jobs**. If needed,
  run **Tag release** with the merge commit from the failed run's summary.
- **r-universe delayed:** check its [builds](https://github.com/r-universe/economic/actions)
  or try the [sync button](https://economic.r-universe.dev/packages).
