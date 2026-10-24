# Maintaining realtalk

## How publishing works

- **A GitHub release publishes.** r-universe builds the latest GitHub release of realtalk, not `main`. Merging to `main` publishes nothing, so `main` can be ahead of what users install.
- **Releases come only from two buttons:** "Publish update", for data updates, and "Tag release", for everything else. Don't create releases by hand from the Releases page; nothing enforces this, but a hand-made release skips every check.
- **The pkgdown site** deploys from each release's tag, so it matches what r-universe serves.

## Who does what

- **Drafters:** anyone with Write access. They press "Draft update" and start the checks on its PR.
- **Maintainers:** the `realtalk-maintainers` team, with the Maintain role. Only their approval lets a PR merge, and only they can press "Publish update" and "Tag release".

## A data update

Every Friday morning, the **New data check** looks for BLS or BEA data that isn't in a draft yet. When it finds some, it opens an issue labeled `new-data` and mentions the maintainers. You don't have to wait for it: when you know new data is out, start at step 1.

| # | Who | Where | What happens |
|---|---|---|---|
| 1 | Anyone with Write access | Actions → **Draft update** → Run workflow | Fetches the data, rebuilds, checks it against FRED, sets the version and the `NEWS.md` entry, runs R CMD check, and opens a PR from the `data-update` branch with a memo of what changed. Nothing is published. If nothing is new, it says so and stops. |
| 2 | Anyone with Write access | The PR → **Approve and run workflows** | Starts the PR's checks, which GitHub holds because a bot opened the PR. |
| 3 | A maintainer | The PR → Files changed → **Review changes** → **Approve** | The sign-off. Read the memo first: coverage, revisions, unexpected revisions, the FRED comparison, and stale inputs. |
| 4 | A maintainer | Actions → **Publish update** → Run workflow | Merges the PR, checks the merge commit, tags it, and creates the release, which publishes. Then it deploys the site and waits for r-universe to serve the new version. |

If a reminder issue is open, the draft PR's description says `Closes #N`, so publishing the draft closes the issue. Otherwise the next Friday check closes it once the draft or `main` has the newest data.

**Notes:**

- **The version** is the draft's date in Eastern time, for example `2026.11.13`, with a suffix such as `2026.11.13.1` if that version is already released.
- **Running "Draft update" again** replaces the draft with the newest data and cancels any approval. Do that if more data comes out before you publish, or if something changed on `main`.
- **Don't push to `data-update` by hand.** "Publish update" refuses a draft that isn't one commit by the bot. Fix problems in their own PR to `main`, then draft again.
- **Dry runs:** "Draft update", "Publish update", and "Tag release" each have a `dry_run` box that runs the checks and creates nothing.

## Other changes

Code fixes and updates to the hand-maintained files in `data-raw/raw/static/` (CPI-U-RS, CPI-U-X1, the minimum wage) go through an ordinary PR:

1. Make the change on a branch, rebuild what it affects, and open a PR. To publish it, bump `Version` in `DESCRIPTION` (the scheme is `YYYY.M.D`) and add a `NEWS.md` entry.
2. A maintainer approves, and the PR is merged with GitHub's merge button. This publishes nothing.
3. A maintainer runs Actions → **Tag release**. It checks the commit and version, runs the checks, then tags and releases the current `main`.

GitHub doesn't count a PR author's own approval, so maintainers approve each other's PRs. As a backup, admins can merge their own PR without an approval, but never without a passing check.

## When something fails

- **"Draft update" fails at the fetch:** BLS or BEA sometimes refuses a request for a moment. BEA's refusals currently show up as "Column `time_period` not found" (Economic/epidatatools#22). Run it again.
- **"Draft update" fails the FRED comparison:** a value differs from FRED. The error names the series and month. Investigate before drafting again.
- **"Publish update" refuses:** its message says why, for example no approval yet, the check hasn't passed, or `main` changed since the draft (draft again).
- **"Publish update" fails after the merge:** the data is on `main` but not published until the release exists. In the failed run, click **Re-run failed jobs**. If that's not possible, run **Tag release** with the merge commit shown in the failed run's summary.
- **The r-universe wait fails after 3 hours:** the release exists but r-universe hasn't built it. Check https://github.com/r-universe/economic/actions.
- **Slow runs:** setting up R on GitHub's runners sometimes takes 15 minutes or more. That's GitHub, not realtalk.

## Settings

These live in GitHub, not in the repository:

- **Rulesets** (Settings → Rules):
  - **"protect main"**: pull requests required; one approval from a code owner; approvals dismissed by new commits; merge commits only; no force pushes or deletion. Admins can bypass it for pull requests.
  - **"require check on main"**: the `check` workflow must pass. Nobody can bypass it.
- **`.github/CODEOWNERS`** names `@economic/realtalk-maintainers`. The team must be visible and have the Maintain role on realtalk, or GitHub ignores the line.
- **Repository secrets:** `BLS_API_KEY`, `BEA_API_KEY`, and `FRED_API_KEY`.
- **r-universe:** realtalk's entry in `economic/economic.r-universe.dev`'s `packages.json` has `"branch": "*release"`.
