# Proposal: button-driven data updates for realtalk

Date: 2026-10-22
Status: design settled 2026-10-22; next, an implementation plan with phases

Based on the CI, refresh, and release design in `~/projects/productivity_pay_gap` (see its `plans/2026-10-21-ci-data-release-workflow.md`), adapted for an R data package that is updated by hand about once a month.

## How an update works

Two workflow buttons, in the Actions tab:

- **Draft update** prepares an update as a pull request (PR). It publishes nothing.
- **Publish update** merges that PR into `main`, which publishes it, and creates the GitHub release page.

Every click, in order:

| # | Who | Where | Button | What it does |
|---|---|---|---|---|
| 1 | Anyone with Write access | Actions tab → "Draft update" | **Run workflow** | Fetches new data, builds everything, writes the memo, and opens a PR with the changes on the `data-update` branch. Nothing is published. |
| 2 | Anyone with Write access | The PR page | **Approve and run workflows** | Starts the automated checks on the PR. GitHub holds them because a bot opened the PR. This only starts the checks; it says nothing about the data. |
| 3 | A member of `realtalk-maintainers` | The PR page → "Files changed" → **Review changes** | **Approve** → **Submit review** | The human sign-off: "I read the memo and the numbers look right." Only a maintainer's approval counts. It makes no commit and publishes nothing. |
| 4 | A member of `realtalk-maintainers` | Actions tab → "Publish update" | **Run workflow** | Checks that steps 2 and 3 happened on the PR's latest commit, merges the PR into `main` (which r-universe builds), and creates the version tag and the GitHub release page. |

Only steps 1 and 4 make commits. Step 1 commits to the `data-update` branch, and step 4 adds the merge commit to `main`. Only step 4 publishes.

### Terms

- **PR (pull request):** a proposed set of changes, shown on its own page, that hasn't reached `main` yet.
- **Merge:** copying a PR's changes into `main`. Here, merging publishes, because r-universe builds whatever is on `main`.
- **"Approve and run workflows"** (step 2) starts the automated checks. It's unrelated to approving the PR.
- **Approving the PR, or a review** (step 3): the human sign-off. Anyone with Write access can click Approve, but only an approval from the `realtalk-maintainers` team lets the PR merge.
- **GitHub release:** the page that lists a version (for example v2026.10.22) with the memo as notes. "Publish update" creates it. "Release" in this document means only that page.

## Decisions so far

| Topic | Decision |
|---|---|
| Schedule | No scheduled updates. Someone with Write access starts each update with a button. A scheduled check only opens a reminder issue when new data is out (see "New-data reminder"). |
| Merge vs. publish | One step. "Publish update" merges the draft PR, which publishes it. `main` always matches what's published, and r-universe keeps building from `main`. (productivity_pay_gap separates merging from releasing because it lets revisions pile up on `main` before a quarterly release. realtalk publishes every update, so a staging step on `main` buys little.) |
| Holding an update | An odd-looking update waits as an open PR. Nothing reaches `main` or r-universe until "Publish update" is pressed. |
| Re-drafting | "Draft update" always force-pushes the rolling `data-update` branch. A new draft replaces the old one, because it has the newest data. Commits added by hand to that branch are lost, so fixes go in their own PR to `main`, followed by a new draft. A new draft also cancels any earlier approval (see the ruleset below). |
| Who drafts | Anyone with Write access. GitHub has no per-workflow permission for `workflow_dispatch`, so there is no drafters team. |
| Who approves | A `realtalk-maintainers` team in the Economic org, with the Maintain role on the repo. (GitHub ignores a code owner's approval if they can't write to the repo; Maintain includes Write.) `CODEOWNERS` names the team for every file, and the ruleset requires a code owner's approval, so only a maintainer's approval lets a PR merge. |
| Who publishes | Only `realtalk-maintainers` can run "Publish update". The team has the Maintain role, drafters have Write, and the plan job refuses anyone below Maintain (admins pass too). GitHub lets anyone with Write run any workflow button, and the built-in token can read a user's repo role but not their team membership, so the role stands in for the team. Maintain adds a few low-risk settings (description, topics, features such as issues) but can't change rulesets, access, or secrets, and doesn't bypass the ruleset. |
| How many approvals | One maintainer's approval is enough, even when that maintainer also pressed "Draft update". The bot is the PR's author, so GitHub allows it. |
| The publish gate | A PR approval enforced by a ruleset on `main`, not a GitHub Environment. Merging to `main` publishes, so an Environment on the publishing job alone would leave GitHub's merge button and direct pushes ungated. |
| Publish button | Keep "Publish update" rather than relying on GitHub's merge button. It's the one obvious publish action for rotating RAs, and the only publish path that checks the presser's role and that `main` hasn't moved. |
| Version | The draft date, `YYYY.M.D` in Eastern time, which reflects the data vintage. It stays the same even if the draft is published days later. If that version is already released (a second draft on a day something was already published), Draft update appends a suffix: `2026.10.22.1`, then `.2`. R orders these correctly. |
| Offline rebuild check | Later, as its own phase after the buttons work. The pipeline would clean from the committed snapshots in `data-raw/raw/snapshots/` instead of straight from the API fetch, so a PR check can rebuild offline and fail if the committed data doesn't match the code, as in productivity_pay_gap. It mainly protects hand-made PRs; data PRs are built fresh by "Draft update". |
| Hand-made PRs by maintainers | GitHub never counts a PR author's own approval. `realtalk-maintainers` has at least two members, so they approve each other's PRs. As a backup, admins can bypass the approval rule for pull requests only; the required check has no bypass. |
| Team membership | `realtalk-maintainers`: benzipperer and zmokhiber, for now. Drafters are whoever has Write access; nothing in the workflows names them. |
| `_targets/meta/meta` | Stop committing it: add it to `data-raw/_targets/.gitignore` and remove it from the index. CI starts with an empty store, so it would change on every run and tell nobody anything. |
| Reminder | A scheduled check every weekday that opens or updates one rolling issue when any fetched source has new data, and @-mentions `@economic/realtalk-maintainers`, who decide who drafts. |
| FRED verification | Runs only in "Draft update", which has the key and runs code from `main`. A mismatch stops the draft. PR checks need no secrets and don't call FRED. (After design review job 200.) |
| Names | The workflows are "Draft update" and "Publish update". "Release" means only the GitHub release page. |

## What's different from productivity_pay_gap

1. **Merging to `main` publishes.** In `economic.r-universe.dev/packages.json`, realtalk has no `branch` field, so r-universe builds whatever is on `main`. pkgdown also deploys on every push to `main`. This design keeps that behavior, and makes "Publish update" the only way data updates reach `main`.
2. **Several people do the updates.** Recent updates were done by Emma Cohn, steviemarvin, zmokhiber, jfast13, and Ben. Notifications and permissions go to whoever pressed the button, not to one hard-coded assignee.
3. **There is no branch protection and no renv.** People push straight to `main` today; the ruleset below ends that. Package versions come from CRAN or Posit Package Manager on each run, so there's no `renv::update()` step.
4. **A monthly update already involves several steps:** fetch the data, bump the date-based version in `DESCRIPTION`, add a `NEWS.md` entry, rebuild the README (its table shows the latest dates, and `README.yaml` fails if it's stale), and commit `data/`, `data-raw/processed/`, `data-raw/raw/snapshots/`, and `_targets/meta/meta`. All of these can be automated.
5. **Some verification already exists.** `tests/testthat/test-data-currency.R` checks the latest values of three monthly series against FRED. It's skipped unless `FRED_API_KEY` is set, so it probably never runs in CI.

## Roles and repository settings

- **Drafters:** anyone with Write access. They press "Draft update", click "Approve and run workflows", read the memo, and request a review from `@economic/realtalk-maintainers`, which notifies the team. They also open hand-made PRs. A drafter may click Approve on the PR, but it doesn't count toward merging.
- **Maintainers:** the `realtalk-maintainers` team, with the Maintain role. They do everything drafters do, their approval is the only one that lets a PR merge, and only they can run "Publish update".
- **Admins:** manage the settings below.

Settings:

- **`CODEOWNERS`:** `* @economic/realtalk-maintainers`.
- **Ruleset "protect main"** (bypass: the Admin role, for pull requests only):
  - pull requests required, so no direct pushes
  - one approval required, from a code owner
  - "Dismiss stale pull request approvals when new commits are pushed", so a new draft cancels an earlier approval
  - merge commits only
  - force pushes and branch deletion blocked
- **Ruleset "require check on main"** (no bypass):
  - the check required

  A bypass skips every rule in its ruleset, so the check sits in a ruleset of its own. That way an admin's bypass skips the approval, but never the check.
- **The team:** at least two members, created in the Economic org and given the Maintain role on realtalk. Depending on the org's settings, creating it may need an org owner, who can then let Ben manage its membership. (GitHub calls that being the team's "team maintainer", which is unrelated to the repo's Maintain role.)

## The workflows

```
[Draft update] ──► PR "Data update 2026.10.22: CPI through Sep, PCE through Aug"
 (Actions tab)        memo in the body, assigned to whoever clicked
                                 │
        anyone: "Approve and run workflows", read memo, request review
        maintainer (realtalk-maintainers): approve the PR
                                 │  (an odd update just waits here)
                                 ▼
[Publish update] ──► merge PR ──► tag v{DESCRIPTION version} + GitHub release (notes = memo)
                                 │
                                 ▼
          r-universe builds main; pkgdown deploys; workflow confirms r-universe
```

### Draft update (`workflow_dispatch`, with a `dry_run` input)

- **Build job** (API secrets, read-only token):
  - fetches fresh data and rebuilds, with an empty targets store
  - sets the version to today's date, with a suffix if that version is already released (see "Version" above)
  - writes the `NEWS.md` entry from the dataset end dates ("update CPI-based data through September 2026", "update PCE through August 2026")
  - rebuilds the README
  - runs the tests and R CMD check
  - runs the FRED verification (see "Verification" in the memo section). If it fails, the build job fails and opens no PR, and GitHub emails the person who pressed the button.
  - writes the memo
  - uploads the changed files and the memo as an artifact
- **PR job** (write token, runs no R):
  - copies only allowlisted files from the build's artifact, as productivity_pay_gap's `copy-refresh-files.sh` does
  - creates the `data-update` branch from the commit the build job used (`github.sha`), not from the current `main`, so the outputs always sit on the code that built them. It then force-pushes the branch. If `main` moved during the build, the PR's base is out of date, and "Publish update" refuses it.
  - opens or updates the PR, assigned to `github.actor`, with the memo as the body
- **If no new data arrived:** it opens no PR, and the run summary says so and shows each dataset's latest period. If a PR is open and `main` already has the same data, it closes that PR.
- **With `dry_run`:** it builds the memo and writes it to the run summary, and touches no branch or PR.

GitHub will probably hold the PR check on a bot-opened PR until someone with Write access clicks "Approve and run workflows", as it does in productivity_pay_gap. That's an extra click, but it's also a deliberate gate: the PR's files come from a job that ran package code.

### Publish update (`workflow_dispatch`, with `dry_run`)

1. **Plan job** (read-only) finds the open `data-update` PR and applies the guards. It refuses if:
   - the person who pressed the button has a role below Maintain on the repo ("Only realtalk-maintainers can publish")
   - there is no open `data-update` PR
   - the PR's required checks haven't passed on its latest commit
   - no maintainer has approved the PR's latest commit. The ruleset would refuse the merge anyway; checking first gives a clearer message.
   - `main` has moved since the draft, meaning the commit the draft was built from isn't the current `main`. Then the merge commit would contain files nobody checked. Re-run "Draft update".
   - the PR's latest commit isn't the draft commit that "Draft update" pushed, for example because someone pushed to `data-update` by hand. The FRED verification ran only on the draft commit.
   - the `DESCRIPTION` version is already tagged, or isn't higher than the last release
   - `NEWS.md` has no entry for that version
2. **Publish job** (write token, runs no R):
   - merges the PR with a merge commit. Since `main` hadn't moved, the merge commit's files are identical to the checked commit's, and the job confirms that by comparing the two trees.
   - creates the tag `v{version}` on the merge commit through the API, which refuses a tag that already exists
   - creates the GitHub release with the memo as notes
3. **Follow-up jobs:**
   - start the pkgdown workflow with `workflow_dispatch`. A push or release made with the built-in token doesn't trigger other workflows, so `pkgdown.yaml` wouldn't fire on its own. r-universe isn't affected, because it watches the git repository rather than GitHub events.
   - poll r-universe until the new version appears, and fail after a time limit, so a failed build there sends a failure email. Right now nobody would notice one.

With `dry_run`, it runs the guards and shows the tag and notes, and merges and creates nothing.

### New-data reminder (scheduled)

A scheduled workflow, `new-data-check`, tells people when an update is worth drafting. It never opens a PR or changes a branch.

- **What it checks:** every source the pipeline fetches: CPI-U NSA and SA and C-CPI-U from the BLS API, and monthly, quarterly, and annual PCE from the BEA API. It runs the pipeline's own fetch and snapshot targets (`tar_make()` limited to the `*_raw_csv` targets) and compares the fresh snapshots with those committed on `main`. Using the same fetch code as "Draft update" means it catches new periods and revisions alike.
- **Hand-maintained files** (CPI-U-RS, the minimum wage, CPI-U-X1) aren't fetched, so the check can't see new releases of them. The issue repeats the memo's stale-input warnings instead, for example CPI-U-RS missing last year's annual value after May.
- **Jobs:** as with "Draft update", the **check job** runs R with the API secrets and a read-only token, and passes a short summary to the **issue job** as a job output. The issue job has `issues: write` and runs no R.
- **The issue:** one rolling issue, labeled `new-data`:
  - **New data, no open issue:** it opens one titled with what's new, for example "New data: CPI through Oct 2026, PCE through Sep 2026", with a checklist pointing to "Draft update". The body @-mentions `@economic/realtalk-maintainers`, which notifies its members. The handle is kept in a repository variable, so changing who's notified doesn't need a code change.
  - **More new data while the issue is open:** it updates the title and body, and comments, which sends one email.
  - **Nothing new since the last notice:** it does nothing, so no email.
  - **`main` has caught up** (after an update is published): it closes the issue.
- **Failures:** if a fetch fails, the run fails, and GitHub emails whoever last changed the workflow's schedule.
- **Schedule:** every weekday at 14:17 UTC (10:17 a.m. EDT, 9:17 a.m. EST), after the 8:30 a.m. Eastern BLS and BEA releases. BLS publishes CPI around mid-month and BEA publishes PCE near the end of the month, so a reminder is at most a day late. The odd minute avoids the top-of-hour rush, when GitHub delays scheduled runs.
- **Manual run:** `workflow_dispatch` too, with a `dry_run` input that writes the summary to the run page and touches no issue.

### Hand-made PRs

Code fixes (for example to `get_price_index()`) and updates to hand-maintained files (`us_minimum_wage.csv`, `r-cpi-u-rs-allitems.csv`, `cpi_u_x1.csv`) go through ordinary PRs. They need a maintainer's approval like any other PR, and are merged with GitHub's merge button. They publish to r-universe as soon as they merge.

To keep the release history complete, a small job runs on every push to `main`. If `DESCRIPTION` has a version with no tag yet, it creates the tag and a GitHub release, with that version's `NEWS.md` entry as notes. After a "Publish update" run, the tag already exists, so this job does nothing.

## The memo: what changed

It would be a `change_memo` target in the pipeline, so it builds the same way locally and in CI. It compares the working tree with the last release tag using the committed `data-raw/processed/*.csv` files, which are easy to diff with `git show <ref>:<path>`. An environment variable can set another baseline ref, as `PPG_BASELINE` does in productivity_pay_gap.

Sections:

1. **Coverage:** each dataset's latest period, before and after. This is the `available_price_indexes` diff.
2. **Revisions:** for each dataset, how many values were revised, the largest revisions, and the range of revised periods. Each revision is labeled expected or unexpected:
   - **Expected:**
     - PCE monthly revisions and the annual update
     - interim C-CPI-U revisions
     - CPI-U SA seasonal factor revisions in February
     - the CPI-U-RS annual update
   - **Unexpected:** any change to historical CPI-U NSA values, which BLS never revises, or a change to a final C-CPI-U value.
3. **Verification:**
   - **FRED comparison**, run only in the "Draft update" build job, which has `FRED_API_KEY` and runs code from `main`:
     - CPI-U NSA (CPIAUCNS) and SA (CPIAUCSL), C-CPI-U (SUUR0000SA0), and PCE (PCEPI), monthly, for the latest 24 months that both sources have, to the precision each dataset publishes
     - a month that FRED hasn't posted yet, usually the newest one on release day, is listed as "not yet on FRED" rather than failing. The memo says which months were verified.
     - any other mismatch fails the build job, so no PR is opened
     - PR checks don't call FRED. They need no secrets, so they work the same for bot, internal, and fork PRs, and their summary says that FRED wasn't checked. For hand-made PRs this costs little: FRED doesn't carry CPI-U-RS, CPI-U-X1, or the minimum wage, which are what those PRs usually change.
   - **Internal consistency checks**, run by the PR check and in the pipeline, with no network:
     - no gaps, apart from the known missing months (`bls_missing` in `data-raw/_targets.R`, currently October 2025). Those months are NA in CPI-U and C-CPI-U, and interpolated in the extended C-CPI-U.
     - no duplicate periods
     - the extended C-CPI-U agrees with C-CPI-U where both have a value from 2000 on, within half a unit of the extended series' rounding (0.05 index points). For monthly data, compare NSA with NSA. Known missing months are skipped. (The extended series is rounded to one decimal; C-CPI-U keeps three.)
     - annual and quarterly values only for complete periods, where a known missing month counts as present: 2025 averages 11 months. This matches `monthly_to_annual()` and `monthly_to_quarterly()` in `data-raw/R/aggregate.R`.
4. **Stale manual inputs:** a warning when a hand-maintained file is overdue. For example, CPI-U-RS is missing last year's annual value after May, or the minimum wage file hasn't been touched in a year. The buttons can't update these; they come through hand-made PRs.
5. **Check results:** R CMD check, the tests, and whether the README is current.

The memo becomes the PR body and the GitHub release notes. The terse `NEWS.md` entry stays separate.

## Gates

| Gate | Where | Blocks? |
|---|---|---|
| R CMD check, tests, and README current | PR check | Yes |
| FRED mismatch | "Draft update" build job (no PR is opened) | Yes |
| Gaps, duplicate periods, incomplete annual or quarterly periods, extended C-CPI-U disagreeing with C-CPI-U, changes to historical CPI-U NSA | PR check | Yes |
| Expected revisions, stale manual inputs | Memo | No |
| A maintainer's approval of the latest commit | Ruleset, on every merge into `main` | Yes |
| PR checks passed, `main` unchanged since the draft, latest commit is the bot's draft commit | Publish update | Yes |
| Version not already released, `NEWS.md` entry present | Publish update | Yes |
| Presser has the Maintain role or higher | Publish update | Yes |

## Accepted risks

- **The merge button on an approved data PR.** Once a maintainer has approved the `data-update` PR, anyone with Write access could press GitHub's merge button instead of "Publish update". That skips the role check and the "main hasn't moved" guard, but not the maintainer's approval or the required check. The job on pushes to `main` still creates the tag and GitHub release. A maintainer has already approved the numbers, so this is accepted. If it becomes a problem, "Publish update" could set a required status that only it can satisfy on `data-update` PRs.

## To verify before building

- A merge made through the API with "Publish update"'s built-in token goes through once a code owner has approved and the check has passed. If it doesn't, the fallback is a GitHub App token, which needs an org admin.
- The held `pull_request` check run on the bot's PR counts as the required check, as it did in productivity_pay_gap.
- A force-push to `data-update` dismisses an earlier approval, with the ruleset setting above.
- r-universe picks up a merge to `main` made by the built-in token, and the polling step can read the new version from the r-universe API.
- Who in the Economic org can create the `realtalk-maintainers` team.
- Whether an @-mention of `@economic/realtalk-maintainers` in an issue written by the built-in token notifies the team's members. A secret team can only be mentioned by its members, so the team must be visible. If it doesn't, the reminder mentions a list of usernames kept in the repo instead.
- Current access on realtalk. On 2026-10-22, zmokhiber's role on the repo read as `admin` (through Ben's token). Admins pass the "Publish update" role check and can use the ruleset bypass, so check whether that admin role is intended before relying on the team for either.
- The repository secrets `BLS_API_KEY`, `BEA_API_KEY`, and `FRED_API_KEY` are set and work from CI. The local `gh` token can't read secret settings, so a test run confirms them, as in productivity_pay_gap's Phase 0. None of realtalk's current workflows use them, so they're probably not set yet.
- The built-in token can read the presser's role (`GET /repos/{owner}/{repo}/collaborators/{username}/permission`).

## Open questions

None. All questions were settled on 2026-10-22.
