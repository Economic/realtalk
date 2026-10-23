# Proposal: button-driven data updates for realtalk

Date: 2026-10-22
Status: design settled 2026-10-22, revised 2026-10-23 so that r-universe builds releases, and simplified 2026-10-23 (see "Accepted risks"); implemented by `plans/2026-10-23-implementation-data-update-workflows.md`

Based on the CI, refresh, and release design in `~/projects/productivity_pay_gap` (see its `plans/2026-10-21-ci-data-release-workflow.md`), adapted for an R data package that is updated by hand about once a month.

## How an update works

Two workflow buttons, in the Actions tab:

- **Draft update** prepares an update as a pull request (PR). It publishes nothing.
- **Publish update** merges that PR into `main` and creates the GitHub release. The release is what publishes: r-universe builds the latest GitHub release.

Every click, in order:

| # | Who | Where | Button | What it does |
|---|---|---|---|---|
| 1 | Anyone with Write access | Actions tab → "Draft update" | **Run workflow** | Fetches new data, builds everything, writes the memo, and opens a PR with the changes on the `data-update` branch. Nothing is published. |
| 2 | Anyone with Write access | The PR page | **Approve and run workflows** | Starts the automated checks on the PR. GitHub holds them because a bot opened the PR. This only starts the checks; it says nothing about the data. |
| 3 | A member of `realtalk-maintainers` | The PR page → "Files changed" → **Review changes** | **Approve** → **Submit review** | The human sign-off: "I read the memo and the numbers look right." Only a maintainer's approval counts. It makes no commit and publishes nothing. |
| 4 | A member of `realtalk-maintainers` | Actions tab → "Publish update" | **Run workflow** | Checks that steps 2 and 3 happened on the PR's latest commit, merges the PR into `main`, and creates the version tag and the GitHub release, which r-universe then builds. |

Only steps 1 and 4 make commits. Step 1 commits to the `data-update` branch, and step 4 adds the merge commit to `main`. Only step 4 publishes, when it creates the release.

### Terms

- **PR (pull request):** a proposed set of changes, shown on its own page, that hasn't reached `main` yet.
- **Merge:** copying a PR's changes into `main`. Merging doesn't publish. `main` can be ahead of what's published.
- **"Approve and run workflows"** (step 2) starts the automated checks. It's unrelated to approving the PR.
- **Approving the PR, or a review** (step 3): the human sign-off. Anyone with Write access can click Approve, but only an approval from the `realtalk-maintainers` team lets the PR merge.
- **GitHub release:** the page that lists a version (for example v2026.10.22), with the memo as notes, on a tag. Creating it publishes: r-universe builds the latest release. "Publish update" and "Tag release" create releases. "Release" in this document means only that page.

## Decisions so far

| Topic | Decision |
|---|---|
| Schedule | No scheduled updates. Someone with Write access starts each update with a button. A scheduled check only opens a reminder issue when new data is out (see "New-data reminder"). |
| What publishes | A GitHub release. realtalk's entry in `economic.r-universe.dev/packages.json` has `"branch": "*release"`, so r-universe builds the most recent GitHub release, not `main`. Merges to `main`, including the many during this project, publish nothing. (Revised 2026-10-23. The first version had r-universe build `main`, so that merging published. That made every development PR a publish.) |
| Merge and publish | One step for data updates. "Publish update" merges the draft PR and creates the release in the same run. |
| Holding an update | An odd-looking update waits as an open PR. Nothing is published until "Publish update" is pressed. |
| Re-drafting | "Draft update" always force-pushes the rolling `data-update` branch. A new draft replaces the old one, because it has the newest data. Commits added by hand to that branch are lost, so fixes go in their own PR to `main`, followed by a new draft. A new draft also cancels any earlier approval (see the ruleset below). |
| Who drafts | Anyone with Write access. GitHub has no per-workflow permission for `workflow_dispatch`, so there is no drafters team. |
| Who approves | A `realtalk-maintainers` team in the Economic org, with the Maintain role on the repo. (GitHub ignores a code owner's approval if they can't write to the repo; Maintain includes Write.) `CODEOWNERS` names the team for every file, and the ruleset requires a code owner's approval, so only a maintainer's approval lets a PR merge. |
| Who publishes | Only `realtalk-maintainers` can run "Publish update" and "Tag release", the two workflows that create releases. The team has the Maintain role, drafters have Write, and each workflow's plan job refuses anyone below Maintain (admins pass too). GitHub lets anyone with Write run any workflow button, and the built-in token can read a user's repo role but not their team membership, so the role stands in for the team. Maintain adds a few low-risk settings (description, topics, features such as issues) but can't change rulesets, access, or secrets, and doesn't bypass the ruleset. |
| How many approvals | One maintainer's approval is enough, even when that maintainer also pressed "Draft update". The bot is the PR's author, so GitHub allows it. |
| What reaches `main` | A PR approval enforced by a ruleset on `main`, not a GitHub Environment, so GitHub's merge button and direct pushes are gated too. |
| Publish button | Keep "Publish update" rather than relying on GitHub's merge button. It's the one obvious publish action for rotating RAs, and the only path that checks the presser's role, that `main` hasn't moved, and that the branch is the bot's draft. |
| Tag release | Manual only (`workflow_dispatch`), limited to the Maintain role. It publishes changes that reached `main` through hand-made PRs, and finishes a "Publish update" whose tag job failed. Nothing creates a release automatically on a push to `main`, so every publish is a deliberate act by a maintainer. |
| pkgdown | Deploys when a release is created, not on every push to `main`, so the site matches what's published. "Publish update" and "Tag release" start it with the release tag, and it builds that tag, because a release created with the built-in token doesn't trigger `release: published`. (After design review job 226.) |
| Version | The draft date, `YYYY.M.D` in Eastern time, which reflects the data vintage. It stays the same even if the draft is published days later. If that version is already released (a second draft on a day something was already published), Draft update appends a suffix: `2026.10.22.1`, then `.2`. R orders these correctly. |
| Offline rebuild check | Later, as its own phase after the buttons work. The pipeline would clean from the committed snapshots in `data-raw/raw/snapshots/` instead of straight from the API fetch, so a PR check can rebuild offline and fail if the committed data doesn't match the code, as in productivity_pay_gap. It mainly protects hand-made PRs; data PRs are built fresh by "Draft update". |
| Hand-made PRs by maintainers | GitHub never counts a PR author's own approval. `realtalk-maintainers` has at least two members, so they approve each other's PRs. As a backup, admins can bypass the approval rule for pull requests only; the required check has no bypass. |
| Team membership | `realtalk-maintainers` has two members for now, including Ben. Drafters are whoever has Write access; nothing in the workflows names them. |
| `_targets/meta/meta` | Stop committing it: add it to `data-raw/_targets/.gitignore` and remove it from the index. CI starts with an empty store, so it would change on every run and tell nobody anything. |
| Reminder | A scheduled check every weekday that opens or updates one rolling issue when any fetched source has new data, and @-mentions `@economic/realtalk-maintainers`, who decide who drafts. |
| API keys | Repository secrets. They are free BLS, BEA, and FRED keys that can be reissued in minutes, so a `main`-only Environment isn't worth its cost: no key-using workflow could be tested from a branch. (Revised 2026-10-23; design review job 208 had moved them to an Environment. See "Accepted risks".) |
| FRED verification | Runs only in "Draft update", which has the key and runs code from `main`. A mismatch stops the draft. PR checks need no secrets and don't call FRED. (After design review job 200.) |
| Merging and tagging | The merge passes the checked head SHA, and the plan job checks that `main` hasn't moved. Everything after the merge is in separate jobs, so "Re-run failed jobs" can finish a failed publish. (After design review job 204; the up-to-date rule it added was dropped 2026-10-23.) |
| Names | The workflows are "Draft update", "Publish update", and "Tag release". "Release" means only the GitHub release page. |

## What's different from productivity_pay_gap

1. **r-universe publishes the package.** productivity_pay_gap publishes files attached to a GitHub release. realtalk is an R package that users install from r-universe. With `"branch": "*release"`, r-universe builds the latest GitHub release, so the release is the publish step here too. Until that setting, r-universe built whatever was on `main`, and pkgdown deployed on every push to `main`.
2. **Several people do the updates.** Recent updates were done by several different RAs and maintainers. Notifications and permissions go to whoever pressed the button, not to one hard-coded assignee.
3. **There is no branch protection and no renv.** People push straight to `main` today; the ruleset below ends that. Package versions come from CRAN or Posit Package Manager on each run, so there's no `renv::update()` step.
4. **A monthly update already involves several steps:** fetch the data, bump the date-based version in `DESCRIPTION`, add a `NEWS.md` entry, rebuild the README (its table shows the latest dates, and `README.yaml` fails if it's stale), commit `data/`, `data-raw/processed/`, `data-raw/raw/snapshots/`, and `_targets/meta/meta`, and create the GitHub release. All of these can be automated.
5. **Some verification already exists.** `tests/testthat/test-data-currency.R` checks the latest values of three monthly series against FRED. It's skipped unless `FRED_API_KEY` is set, so it probably never runs in CI.

**Until the buttons exist**, updates keep the current routine: update locally, merge, and create the GitHub release by hand, as every recent update has. With `"*release"`, that release is what r-universe builds. A merge without a release publishes nothing.

## Roles and repository settings

- **Drafters:** anyone with Write access. They press "Draft update", click "Approve and run workflows", read the memo, and request a review from `@economic/realtalk-maintainers`, which notifies the team. They also open hand-made PRs. A drafter may click Approve on the PR, but it doesn't count toward merging.
- **Maintainers:** the `realtalk-maintainers` team, with the Maintain role. They do everything drafters do, their approval is the only one that lets a PR merge, and only they can run "Publish update" and "Tag release".
- **Admins:** manage the settings below.

Settings:

- **r-universe:** realtalk's entry in `economic.r-universe.dev/packages.json` has `"branch": "*release"`.
- **`CODEOWNERS`:** `* @economic/realtalk-maintainers`.
- **Ruleset "protect main"** (bypass: the Admin role, for pull requests only):
  - pull requests required, so no direct pushes
  - one approval required, from a code owner
  - "Dismiss stale pull request approvals when new commits are pushed", so a new draft cancels an earlier approval
  - merge commits only
  - force pushes and branch deletion blocked
- **Ruleset "require check on main"** (no bypass):
  - the check required. Branches don't have to be up to date before merging, so hand-made PRs don't need "Update branch" and a fresh approval each time `main` moves.

  A bypass skips every rule in its ruleset, so the check sits in a ruleset of its own. That way an admin's bypass skips the approval, but never the check.
- **Repository secrets:** `BLS_API_KEY`, `BEA_API_KEY`, and `FRED_API_KEY`. Only the "Draft update" build job and the reminder's check job use them.
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
     r-universe builds the release; pkgdown deploys; workflow confirms r-universe
```

### Draft update (`workflow_dispatch`, with a `dry_run` input)

- **Build job** (the API keys, read-only token). Runs only from `main`, so drafts are always built from `main`'s code:
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
- **Two cases, compared with `main` only:** if the fresh data equals `main`'s, it opens no PR, closes any open draft PR with "`main` already has these numbers", and the run summary shows each dataset's latest period. Otherwise it force-pushes a new draft, even if the data equals the open draft's. That cancels any approval, which costs one re-approval in the rare case of a re-run with nothing new.
- **With `dry_run`:** it builds the memo and writes it to the run summary, and touches no branch or PR.

GitHub will probably hold the PR check on a bot-opened PR until someone with Write access clicks "Approve and run workflows", as it does in productivity_pay_gap. That's an extra click, but it's also a deliberate gate: the PR's files come from a job that ran package code.

### Publish update (`workflow_dispatch`, with `dry_run`)

1. **Plan job** (read-only) finds the open `data-update` PR and applies the guards. It refuses if:
   - the person who pressed the button has a role below Maintain on the repo ("Only realtalk-maintainers can publish")
   - there is no open `data-update` PR
   - the PR's required checks haven't passed on its latest commit
   - no maintainer has approved the PR's latest commit. The ruleset would refuse the merge anyway; checking first gives a clearer message.
   - `main` has moved since the draft, meaning the commit the draft was built from isn't the current `main`. Then the merge commit would contain files nobody checked. Re-run "Draft update".
   - the branch doesn't hold exactly one commit beyond its base, authored by `github-actions[bot]`, for example because someone pushed to `data-update` by hand. The FRED verification ran only on the bot's commit. This catches accidents; it doesn't stop a deliberately forged commit (see "Accepted risks").
   - the `DESCRIPTION` version is already tagged, or isn't higher than the last release
   - `NEWS.md` has no entry for that version
2. **Merge job** (write token, runs no R):
   - merges the PR with a merge commit through the API, passing the PR head SHA that the plan job checked, so GitHub refuses the merge if the head changed in between
   - compares the merge commit's tree with the checked head's and notes the result in the run summary. They match unless something merged into `main` in the seconds since the plan job. Either way, the check job then runs on the merge commit, which is what gets released.
3. **Check job:** runs the PR check workflow (through `workflow_call`) on the merge commit. The built-in token's merge triggers no workflows, so without this job no check would ever run on the commit that gets released. If it fails, the update is on `main` but not published.
4. **Tag job** (write token, runs no R), after the check job. It runs the shared tagging logic (see "Tag release" below) with the merge commit the merge job recorded. Creating the release is the step that publishes.
5. **Follow-up jobs:**
   - start the pkgdown workflow with `workflow_dispatch`, passing the release tag. pkgdown gets a `ref` input and builds that ref, not the branch it was started on, so the site matches the release even when `main` is ahead of it. A push or release made with the built-in token doesn't trigger other workflows, so `pkgdown.yaml` wouldn't fire on its own. r-universe isn't affected, because it reads releases from GitHub rather than reacting to GitHub events.
   - poll r-universe until the new version appears, and fail after a time limit, so a failed build there sends a failure email. Right now nobody would notice one.

With `dry_run`, it runs the guards and shows the tag and notes, and merges and creates nothing.

**Recovery after a failure past the merge.** Once the merge succeeds, a new "Publish update" run would refuse, because the PR is closed. Until the tag job creates the release, the update is on `main` but not published. Everything after the merge is in separate jobs that are safe to repeat:

- In the failed run, click "Re-run failed jobs". GitHub reruns only the failed jobs and the ones after them, not the plan or merge jobs.
- If the run can't be rerun and no release exists yet, run "Tag release" with the merge commit shown in the failed run's summary.

### Tag release (`workflow_dispatch` only)

A maintainer runs it to publish what's on `main` when it didn't come through "Publish update": a code fix, or an update to a hand-maintained file. It also finishes a "Publish update" whose tag job failed. Nothing runs it automatically.

- **Input:** an optional commit. Without one, the target is the current `main`.
- **Guards** (plan job, read-only). It refuses if:
  - the person who pressed the button has a role below Maintain
  - the target commit isn't on `main`'s first-parent history
  - the version is already released, or isn't higher than the last release
  - `NEWS.md` at the target commit has no entry for that version

  If a follow-up job fails after the release exists (pkgdown, say), use "Re-run failed jobs" in that run, or start pkgdown by hand with the tag.
- **Check job:** runs the PR check workflow (through `workflow_call`) on the target commit, and stops if it fails. A merge made by "Publish update" uses the built-in token, so GitHub ran no checks on the merge commit itself; this job runs them.
- **Then** the shared tagging logic, and the same follow-up jobs as "Publish update": pkgdown and the r-universe check.

**Shared tagging logic**, used by "Tag release" and by the tag job in "Publish update":

1. **The target commit and version:** the given commit (the "Publish update" tag job always passes its merge commit), or the current `main` when "Tag release" is run without one. The version is the one in `DESCRIPTION` at the target commit, not on today's `main`, so a later merge can't change what an earlier publish gets tagged as. Every change reaches `main` as a merge commit, so the target is never a commit inside a PR.
2. **The tag:** if `v{version}` is missing, create it on the target commit. If it points at the target commit, it's done. If it points anywhere else, stop with an error.
3. **The GitHub release**, checked separately from the tag: if no release exists for the tag, create it and mark it latest. The notes are the merged PR's memo when the target is a "Publish update" merge, and otherwise that version's `NEWS.md` entry. An existing release is left alone.

Each step checks what already exists, so any run can be repeated safely.

**One publish at a time.** "Publish update" and "Tag release" share one workflow-level concurrency group, `publish`, with `cancel-in-progress: false`. GitHub then runs at most one of them at a time. It's one line of YAML. (After design review job 238.)

### New-data reminder (scheduled)

A scheduled workflow, `new-data-check`, tells people when an update is worth drafting. It never opens a PR or changes a branch.

- **What it checks:** every source the pipeline fetches: CPI-U NSA and SA and C-CPI-U from the BLS API, and monthly, quarterly, and annual PCE from the BEA API. It runs the pipeline's own fetch and snapshot targets (`tar_make()` limited to the `*_raw_csv` targets) and compares the fresh snapshots with those committed on `main`. Using the same fetch code as "Draft update" means it catches new periods and revisions alike.
- **Hand-maintained files** (CPI-U-RS, the minimum wage, CPI-U-X1) aren't fetched, so the check can't see new releases of them. The issue repeats the memo's stale-input warnings instead, for example CPI-U-RS missing last year's annual value after May.
- **Jobs:** as with "Draft update", the **check job** runs R with the API keys and a read-only token, and passes a short summary to the **issue job** as a job output. The issue job has `issues: write` and runs no R.
- **The issue:** one rolling issue, labeled `new-data`:
  - **New data, no open issue:** it opens one titled with what's new, for example "New data: CPI through Oct 2026, PCE through Sep 2026", with a checklist pointing to "Draft update". The body @-mentions `@economic/realtalk-maintainers`, which notifies its members. The handle is kept in a repository variable, so changing who's notified doesn't need a code change.
  - **More new data while the issue is open:** it updates the title and body, and comments, which sends one email.
  - **Nothing new since the last notice:** it does nothing, so no email.
  - **`main` has caught up** (after an update is merged): it closes the issue.
- **Failures:** if a fetch fails, the run fails, and GitHub emails whoever last changed the workflow's schedule.
- **Schedule:** every weekday at 14:17 UTC (10:17 a.m. EDT, 9:17 a.m. EST), after the 8:30 a.m. Eastern BLS and BEA releases. BLS publishes CPI around mid-month and BEA publishes PCE near the end of the month, so a reminder is at most a day late. The odd minute avoids the top-of-hour rush, when GitHub delays scheduled runs.
- **Manual run:** `workflow_dispatch` too, with a `dry_run` input that writes the summary to the run page and touches no issue.

### Hand-made PRs

Code fixes (for example to `get_price_index()`) and updates to hand-maintained files (`us_minimum_wage.csv`, `r-cpi-u-rs-allitems.csv`, `cpi_u_x1.csv`) go through ordinary PRs. They need a maintainer's approval like any other PR, and are merged with GitHub's merge button. Merging publishes nothing. To publish, the PR (or a later one) bumps the version in `DESCRIPTION` and adds a `NEWS.md` entry, and a maintainer runs "Tag release".

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
     - the extended C-CPI-U agrees with C-CPI-U from 2000 on, the period where the extended series is built from C-CPI-U itself, with a tolerance set by frequency:
       - **monthly NSA:** within 0.05 index points, half a unit of the extended series' one-decimal rounding. Known missing months are skipped.
       - **annual:** within 0.05. They agree exactly today.
       - **quarterly NSA:** within 0.1, one rounding unit, because the extended quarterly values average monthly values that were already rounded. Five quarters differ by exactly 0.1 today, for example 2012 Q2 (132.1 against 132.2). Quarters that contain a known missing month are skipped, because the extended series interpolates that month and C-CPI-U leaves it out.

       (On 2026-10-22, the committed data passed these tolerances, apart from December 1999, which comes before 2000 and is built from CPI-U-RS by design.)
     - annual and quarterly price index values only for complete periods, where a known missing month counts as present: 2025 averages 11 months. This matches `monthly_to_annual()` and `monthly_to_quarterly()` in `data-raw/R/aggregate.R`. It doesn't apply to the minimum wage, whose annual value is the year's highest rate (`create_fed_mw_annual()`), including the partial first year, 1938.
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
| PR checks passed, `main` unchanged since the draft, the branch is one commit by the bot | Publish update | Yes |
| Version not already released, `NEWS.md` entry present | Publish update, Tag release | Yes |
| Presser has the Maintain role or higher | Publish update, Tag release | Yes |
| Checks run and passed on the commit to release | Publish update, Tag release | Yes |

## Accepted risks

Simplified on 2026-10-23. These are situations that need two people working at once, a Write user acting in bad faith, or a rare failure followed by an unusual recovery. One or two maintainers work on this repo, almost never at the same time, so each was judged not worth its mechanism.

- **API keys readable by a Write user.** A Write user could run an edited workflow from a branch that prints the repository secrets. The keys are free and can be reissued in minutes.
- **A forged draft commit.** The "one commit by the bot" guard can be fooled by a commit whose author is set to `github-actions[bot]` by hand. Pushing it would still cancel the maintainer's approval, and the maintainer sees the new commit before approving again.
- **A merge in the seconds between "Publish update"'s plan and merge jobs.** The released commit would then include that other change. The check still runs on the merge commit, and the run summary notes the tree mismatch.
- **Rerunning an old, failed publish after a newer one.** If publish A's tag job fails, publish B succeeds, and someone then reruns A's failed jobs, A would be marked latest and r-universe would build the older data. Don't rerun a publish after a newer one went out; the concurrency group prevents the overlapping version of this.

- **A release created by hand.** Anyone with Write access can create a GitHub release from the Releases page or the API, pointing at any branch or commit, and r-universe would build it. That skips every gate: the ruleset on `main`, the checks, and the role check. Nothing enforces "releases come only from 'Publish update' and 'Tag release'". People with Write access are EPI staff, so the realistic risk is a mistake, and the Releases form targets `main` unless someone picks another branch. Once the workflows exist, the README and `AGENTS.md` say that releases come only from them, never by hand. If this ever matters, a tag ruleset on `v*` with a GitHub App as the only bypass, its key in an Environment limited to `main`, would enforce it without changing anything else. (Accepted 2026-10-23, after design review job 226.)

- **The Maintain-role check is a convenience, not a security boundary.** It protects the copies of "Publish update" and "Tag release" on `main`. A Write user could run an edited copy from their own branch that skips it. That copy still can't merge without a maintainer's approval of the latest commit and the required check, because the ruleset applies to the bot's merge too. The ruleset is the boundary for `main`. Creating a release is covered by the risk above.

- **The merge button on an approved data PR.** Once a maintainer has approved the `data-update` PR, anyone with Write access could press GitHub's merge button instead of "Publish update". That skips the role check and the check that the branch is one commit by the bot. It doesn't skip the maintainer's approval or the required check, and it publishes nothing: the update waits on `main` until a maintainer runs "Tag release". So this is accepted.

## To verify before building

- A merge made through the API with "Publish update"'s built-in token goes through once a code owner has approved and the check has passed. If it doesn't, the fallback is a GitHub App token, which needs an org admin.
- The held `pull_request` check run on the bot's PR counts as the required check, as it did in productivity_pay_gap.
- A force-push to `data-update` dismisses an earlier approval, with the ruleset setting above.
- With `"*release"`, r-universe builds a release created by the built-in token, and the polling step can read the new version from the r-universe API.
- Who in the Economic org can create the `realtalk-maintainers` team.
- Whether an @-mention of `@economic/realtalk-maintainers` in an issue written by the built-in token notifies the team's members. A secret team can only be mentioned by its members, so the team must be visible. If it doesn't, the reminder mentions a list of usernames kept in the repo instead.
- Current access on realtalk: the second maintainer also has the Admin role, which passes the role check and can use the ruleset bypass. Confirmed as intended on 2026-10-23.
- `BLS_API_KEY`, `BEA_API_KEY`, and `FRED_API_KEY` are set as repository secrets and work from CI. The local `gh` token can't read secret settings, so a test run confirms them, as in productivity_pay_gap's Phase 0.
- The built-in token can read the presser's role (`GET /repos/{owner}/{repo}/collaborators/{username}/permission`).

## Open questions

None. All questions were settled on 2026-10-22 and 2026-10-23.
