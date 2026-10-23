# Implementation plan: button-driven data updates

Date: 2026-10-23
Status: draft for review (open questions at the end)

This plan builds the design in `plans/2026-10-22-gha-data-release-workflow.md` (the "design" below). The design's "Decisions so far" and "Accepted risks" are settled; this plan only orders the work and makes it concrete.

## How every phase works

- Each phase happens on its own branch and ends with a PR, merged with a merge commit.
- Commit small. The post-commit hook reviews every commit; triage findings as `AGENTS.md` says.
- Before opening a phase's PR, run the checkpoint review and settle its findings:

  ```sh
  roborev review --branch --base main --panel checkpoint_panel --wait
  ```

- Record results under the phase's "Results" heading in this plan, with dates and run IDs, as productivity_pay_gap's plan does.
- Merging publishes nothing, since r-universe builds the latest release. No phase creates a tag or release, except the first real "Publish update" in Phase 5.
- From Phase 3 on, merging needs a maintainer's approval: zmokhiber approves Ben's PRs, or Ben uses the admin bypass.

### A testing constraint

The API keys live in the `data-apis` Environment, limited to `main`. A workflow that needs them can't run from a branch, which is the point. So for "Draft update" and the reminder:

- The R functions are tested locally, with the keys from `.Renviron`, and with fixtures for failure cases.
- The shell scripts are tested locally with a stand-in `gh` that logs its calls, as in productivity_pay_gap's Phase 6.
- The workflows run for real only after merging, first as dry runs on `main`.

GitHub also starts a `workflow_dispatch` workflow only once its file exists on the default branch. So every new button workflow ("Draft update", "Publish update", "Tag release", the reminder) is first run after its PR merges, as a dry run on `main`, before any real run. Merging a button workflow is safe: it does nothing until a maintainer presses it, and pressing it for real only matters once a draft PR exists. The PR check is triggered by `pull_request`, so it runs on its own PR before merging.

## Before Phase 0: review harness (done 2026-10-22)

PR #34: `.roborev.toml`, `AGENTS.md`, the design, and its design review. Economic/economic.r-universe.dev#2 added `"branch": "*release"`.

## Phase 0: feasibility checks

Settings and spikes that later phases depend on. Throwaway workflows that need no keys go on `spike/*` branches and are deleted afterward.

1. **r-universe sync.** Confirm `https://economic.r-universe.dev/api/packages/realtalk` reports the release, not `HEAD` (it read `RemoteRef: HEAD` on 2026-10-23). Record the field names the poll step in Phase 5 will read.
2. **Environment `data-apis`.** Create it with deployment branches limited to `main`, and add `BLS_API_KEY`, `BEA_API_KEY`, and `FRED_API_KEY`. Confirm there are no repository-level copies.
3. **Keys from CI, from `main` only.** The Environment stays limited to `main` throughout; adding a branch to it, even briefly, would let any Write user run edited code on that branch with the keys.
   - Merge a small `smoke-test.yml` (`workflow_dispatch`, Environment `data-apis`, `contents: read`) to `main` through a PR. It reports whether each key is set, never its value, and makes one small BLS, BEA, and FRED call. Merging publishes nothing.
   - Run it from `main`: every call succeeds.
   - Run it from a `spike/*` branch: the job must fail to reach the Environment. That confirms the branch limit.
   - Remove `smoke-test.yml` in a follow-up PR, or keep it as a diagnostic (decide when recording the results).
4. **Role lookup with the built-in token.** The spike calls `GET /repos/{owner}/{repo}/collaborators/{actor}/permission` with `github.token` and prints `role_name` for the person who started it.
5. **Package install for the pipeline.** The spike installs the pipeline's packages (see Phase 1, step 2) on `ubuntu-24.04` and loads them. Record the time and any missing system libraries, as productivity_pay_gap found with `libglpk`.
6. **Access review.** Check zmokhiber's Admin role on realtalk, and whether it's intended (design, "To verify").

**Exit criteria:** the keys work only from allowed branches; the role lookup works with the built-in token; the pipeline's packages install on the runner.

**Results:** (to fill in)

## Phase 1: pipeline changes (local)

1. **Stop committing `_targets/meta/meta`.** Change `data-raw/_targets/.gitignore` to ignore everything but itself, and `git rm --cached data-raw/_targets/meta/meta`.
2. **Declare the pipeline's packages.** Add `Config/Needs/pipeline:` to `DESCRIPTION`, listing what `data-raw/packages.R` loads (`targets`, `tarchetypes`, `tidyverse`, `readxl`, `economic/epidatatools`, `economic/epitargets`, `tsibble`, `cli`, `assertr`, `conflicted`, `usethis`, plus `desc` and `gert` if steps 5 and 6 use them). CI installs them with `setup-r-dependencies` and `needs: pipeline`.
3. **Consistency tests**, in `tests/testthat/test-data-consistency.R`. They read the package's own datasets, need no network, and so run in R CMD check, in the PR check, and in r-universe's own check. Each check from the design's "Internal consistency checks" gets its own test, and each test is first shown to fail on deliberately broken data:
   - no gaps apart from the known missing months. The pipeline and the test must read the list from one place (open question 3).
   - no duplicate periods, in every dataset
   - extended C-CPI-U against C-CPI-U from 2000, by frequency: monthly NSA and annual within 0.05, quarterly NSA within 0.1, skipping known missing months and the quarters that contain them
   - annual and quarterly price index values only for complete periods, counting a known missing month as present; not applied to the minimum wage
4. **The memo**, as a `change_memo` target in `data-raw/R/memo.R`. It writes `reports/change_memo.md` (`reports/` ignored by git and `.Rbuildignore`).
   - **Baseline:** the latest published release, the one r-universe builds, so the memo describes what users would receive. A tag without a published release (possible mid-recovery in Phase 5) is never the baseline. `REALTALK_BASELINE` overrides it. The workflows resolve the latest release with `gh release view --json tagName` and pass it in `REALTALK_BASELINE`. Locally, the memo does the same through `gh`, and stops with a clear message if `gh` isn't available and `REALTALK_BASELINE` isn't set. Baseline files come from `git show <ref>:data-raw/processed/<name>.csv`.
   - **Sections:** coverage, revisions (with expected and unexpected labels), verification, stale manual inputs, and check results, as in the design. Each section is a function that returns a small table, and one function assembles the Markdown, as productivity_pay_gap's `R/report.R` does.
   - **Unexpected revisions:** a separate function, `find_unexpected_revisions(baseline, current)`, returns changed historical CPI-U NSA values and changed final C-CPI-U values. The memo lists them, and the PR check fails on them (Phase 2), with the same latest-release baseline.
     - **Final C-CPI-U** is judged in the **baseline** vintage: a value is final if it is 12 or more months older than the baseline's latest month. With the baseline through June 2026, June 2025 and earlier are final, and July 2025 is interim. BLS revises interim values quarterly and makes them final 10 to 12 months after first publication ([BLS](https://www.bls.gov/cpi/additional-resources/chained-cpi-questions-and-answers.htm)), so the newest revision a final value could get is already behind it. The history agrees: v2026.8.12 revised July 2025 to June 2026 (July 2025 from 179.236 to 179.272) against v2026.7.14, whose data ran through June 2026: those months were 0 to 11 months old there, all interim, and June 2025, 12 months old, wasn't revised. Releases from v2026.9.11 to v2026.10.14 revised none.
   - The target always reruns (`cue = tar_cue(mode = "always")`), since its baseline is outside the pipeline.
5. **FRED verification**, as a `fred_verification` target in `data-raw/R/verify.R`:
   - compares CPIAUCNS, CPIAUCSL, SUUR0000SA0, and PCEPI with the matching monthly datasets for the latest 24 months both have, through `epidatatools::get_fred()`, at each dataset's precision
   - months FRED doesn't have yet are listed as "not yet on FRED"
   - any other mismatch stops the pipeline with a `cli_abort()` naming the series and months
   - without `FRED_API_KEY`, it warns and records "not run", unless `REALTALK_REQUIRE_FRED=true`, which "Draft update" sets, so a missing key fails there
   - the memo's verification section reads its result
6. **Update helpers** in `data-raw/R/update.R`, used by "Draft update" but runnable locally:
   - `next_version(date, released_tags)`: `YYYY.M.D` in Eastern time, with `.1`, `.2` when that version is already released
   - `news_entry(available_before, available_after)`: the terse lines, for example "update CPI-based data through September 2026", from the coverage diff
   - writing the version to `DESCRIPTION` and the entry to `NEWS.md` happens in a small script, `data-raw/prepare_update.R`, not in a target, because it changes files outside the pipeline's outputs
7. **`test-data-currency.R`:** keep or remove (open question 2).

**Verification:**

- `tar_make(names = c(change_memo))` with `REALTALK_BASELINE=v2026.9.11` against the v2026.10.14 working tree: the memo shows CPI-based data through September 2026, PCE through August 2026, PCE revisions labeled expected, and no unexpected revisions.
- The same with the baseline at `HEAD`: the memo reports no changes.
- A copy of the data with one historical CPI-U NSA value changed: `find_unexpected_revisions()` returns it.
- The real v2026.7.14 to v2026.8.12 transition: `find_unexpected_revisions()` returns nothing, though 11 C-CPI-U months were revised. A copy of v2026.8.12 with June 2025 C-CPI-U changed (final in the v2026.7.14 vintage) returns that month.
- `fred_verification` passes on today's data with the key, records "not run" without it, and fails with `REALTALK_REQUIRE_FRED=true` and no key. A fixture with one value changed fails with a message naming it.
- `devtools::test()` and `devtools::check()` pass. Each consistency test fails on its broken-data fixture.
- `next_version()`: today's date; a same-day suffix; a date in daylight saving time and one not.
- Run `tar_make()` scoped to the changed targets, as `.claude/rules/r_targets.md` requires, and confirm no committed data changes.

**Results:** (to fill in)

## Phase 2: the PR check and pkgdown

1. **`.github/workflows/check.yml`**, one job named `check`, on `ubuntu-24.04`, triggered by `pull_request` to `main`, `push` to `main`, `workflow_dispatch`, and `workflow_call` with a `ref` input. No secrets; `contents: read`.
   - check out `ref` (or the event's commit) with full history and tags, for the revision check, and `persist-credentials: false`
   - install the package's and the pipeline's dependencies
   - R CMD check, with the tests, including the consistency tests
   - fail if the README is stale: `devtools::build_readme()`, then `git diff --exit-code -- README.md`
   - fail on unexpected revisions: run `find_unexpected_revisions()` against the latest release tag
   - write to the job summary that FRED wasn't checked here
2. **Replace `R-CMD-check.yaml` and `README.yaml`** with `check.yml`, so one check named `check` can be required (open question 1). Update the README badge.
3. **`pkgdown.yaml`:**
   - on pull requests: build only, as now
   - on `workflow_dispatch` with a `ref` input: check out that ref, build, and deploy. "Publish update" and "Tag release" pass the release tag.
   - on `release: published`: build the release's tag and deploy. A release created by a person still triggers this, which covers the manual routine until the buttons exist.
   - no deploy on pushes to `main`
4. **Pin actions** to commit SHAs with the version in a comment, as productivity_pay_gap does, and set `permissions` per job.

**Verification:**

- This phase's own PR: `check` passes.
- A throwaway PR that changes `README.Rmd` without rebuilding: `check` fails on the README step.
- A throwaway PR that changes one historical CPI-U NSA value in `data-raw/processed/` and `data/`: `check` fails on the revision step and names the value.
- A throwaway PR that breaks a consistency rule: `check` fails in the tests.
- After merging: a manual pkgdown run with `ref` set to `v2026.10.14` deploys the site from that tag.

**Results:** (to fill in)

## Phase 3: team, rulesets, and settings

Mostly GitHub settings, recorded here and in the README's maintainer section (Phase 7). The repo change is `CODEOWNERS`.

1. **Team `realtalk-maintainers`** in the Economic org: visible, members benzipperer and zmokhiber, Maintain role on realtalk. May need an org owner; Ben as team maintainer.
2. **`.github/CODEOWNERS`:** `* @economic/realtalk-maintainers`.
3. **Ruleset "protect main"** and **ruleset "require check on main"**, exactly as the design's "Roles and repository settings" lists, with the `check` job from Phase 2 as the required check.
4. **Repository variable** `REMINDER_MENTION` = `@economic/realtalk-maintainers`, for Phase 6.

**Verification**, with throwaway PRs closed afterward:

- A direct `git push` to `main` is rejected.
- A PR approved by a non-maintainer can't merge; approved by a maintainer, it can.
- After approval, a new commit on the PR dismisses the approval.
- A PR whose branch is behind `main` can't merge until updated.
- The admin bypass lets Ben merge his own PR without approval, but not with a failing `check`.
- Requesting a review from the team notifies both members.

**Results:** (to fill in)

## Phase 4: Draft update

1. **`.github/workflows/draft-update.yml`** (`workflow_dispatch`, `dry_run` input), as the design describes:
   - **build job:** Environment `data-apis`, `contents: read`, refuses to run unless `github.ref` is `refs/heads/main`. It runs `tar_make()` with an empty store and `REALTALK_REQUIRE_FRED=true`, then `data-raw/prepare_update.R`, `devtools::build_readme()`, and R CMD check. It writes the memo to the run summary and uploads the changed files as an artifact. Whether anything changed is decided in the PR job, which can see the open draft (step 3).
   - **PR job:** `contents: write`, `pull-requests: write`, `issues: write` (for the assignee), no R. It runs after every successful build that isn't a dry run. The build job decides nothing about changes; the PR job makes the one decision, in step 3, from the artifact, the open draft, and `main`.
2. **`.github/scripts/copy-draft-files.sh`:** copies only regular files at allowlisted paths from the artifact: `data/*.rda`, `data-raw/processed/*.csv`, `data-raw/raw/snapshots/*.csv`, `DESCRIPTION`, `NEWS.md`, `README.md`, `man/figures/README-*.png`, and `reports/change_memo.md`. Adapted from productivity_pay_gap's `copy-refresh-files.sh`.
3. **`.github/scripts/update-draft-pr.sh`:**
   - builds `data-update` from the build's commit, commits as `github-actions[bot]`, and force-pushes
   - opens the PR, or updates its title and body: title "Data update {version}: {coverage}", body the memo, assignee `github.actor`, review requested from `@economic/realtalk-maintainers`
   - **decides what to do** by comparing the fresh `data-raw/processed/` files with the newest data already proposed: the open draft branch if there is one, otherwise `main`:
     - **different:** force-push the new draft and update the PR. The newer data replaces the old draft, which also cancels its approval.
     - **same as the open draft, and the draft's base is still the current `main`:** leave the PR alone, so an approval stands. Only the date-based version would differ, and that isn't new data. This is how the design's "a new draft replaces the old one, because it has the newest data" applies when nothing is newer.
     - **same as the open draft, but `main` has moved** (a code-only merge since the draft): rebuild the draft on the new base, as for "different". "Publish update" would refuse the old draft, so keeping it would leave no way forward. This cancels the approval and makes a new `draft-commit` record.
     - **no open draft, and same as `main`:** do nothing
     - **an open draft whose data `main` already has** (for example after a hand-made PR brought the same data in): close it with "`main` already has these numbers"
   - records the draft commit's SHA in a 90-day artifact named `draft-commit`, uploaded by this run. That is the trusted record for "Publish update"'s "bot's draft commit" guard. The SHA also goes in the PR body, for people to read; nothing trusts the body, because anyone with Write access can edit it.

**Verification:**

- Local: both scripts against crafted artifacts (a `.git/config`, a symlink, a nested path, an unexpected file name) are rejected and copy nothing. `update-draft-pr.sh` with a stand-in `gh`: new PR, updated PR, stale PR closed.
- After merging, on `main`: a dry run writes the memo to the run summary and touches no branch.
- The first real run, when new data is out: it opens the PR, assigned to whoever pressed it, with the memo; the held check appears, and approving the run makes `check` pass.
- A second run before publishing, with no new source data: the PR's head SHA and its approval, if any, are unchanged, and the log says the data matches the open draft.
- A code-only merge to `main` while a draft is open, then a run with no new source data: the draft is rebuilt on the new `main`, its approval is cancelled, and "Publish update" accepts the new draft. Locally, with a stand-in `gh` and a fixture where the data is unchanged but the base moved.
- After the first draft is published (Phase 5), with no draft PR open: a run with no new data does nothing.
- The stale-draft case, with `update-draft-pr.sh` and a stand-in `gh`: an open draft whose data `main` already has is closed. This case needs a hand-made PR to bring the same data into `main`, which is rare, so it's tested locally rather than staged for real.

**Results:** (to fill in)

## Phase 5: Publish update and Tag release

1. **`.github/scripts/tag-release.sh`**, the shared tagging logic from the design: target and version, the superseded check, the tag, and the release, each checking what exists first.
2. **`.github/workflows/publish-update.yml`** (`workflow_dispatch`, `dry_run`), with the jobs from the design: plan, merge, check (calls `check.yml` with the merge commit), tag, and the follow-ups (pkgdown with the tag, and the r-universe poll). Concurrency group `publish`, `cancel-in-progress: false`.
   - **`.github/scripts/publish-plan.sh`:** the guards: role, open PR, checks passed and maintainer approval on the latest commit, the latest commit is the draft commit, `main` hasn't moved, version not released and higher, `NEWS.md` entry.
   - **The draft-commit guard** looks through recent successful runs of `.github/workflows/draft-update.yml` on `main` (`gh run list --workflow draft-update.yml --branch main --status success`) for the one whose `draft-commit` artifact equals the PR head. Dry runs and runs that pushed nothing upload no artifact, so they are skipped, and a dry run after a draft doesn't hide the draft's record.
     - **Only trusted runs count:** a run counts only if its `event` is `workflow_dispatch`, its `head_repository` is `Economic/realtalk`, and its `head_branch` is `main`. A pull request, including one from a fork, runs its own edited copy of the workflow, and a fork's branch can be named `main`. The event and repository fields rule those runs out.
     - **The build commit:** the run's `head_sha` must be the PR's base, the commit the draft was built from. That ties the record to the code that built it. A Write user can edit the PR body, or run an edited copy of the workflow from another branch, but can't add an artifact to a run of the real workflow on `main`. If the artifact has expired, the guard refuses and asks for a new draft.
   - **The merge job:** `PUT /repos/{owner}/{repo}/pulls/{n}/merge` with `merge_method=merge` and `sha` set to the checked head, then the tree comparison.
3. **`.github/workflows/tag-release.yml`** (`workflow_dispatch` with an optional commit input, `dry_run`): the guards from the design, then `check.yml` on the target, `tag-release.sh`, and the follow-ups. Same concurrency group.
4. **The r-universe poll:** reads the version from the API every 5 minutes, and fails after 3 hours (open question 5).

**Verification:**

- Local, with a stand-in `gh`, for `tag-release.sh`: a new tag and release; a rerun with both existing; a tag on another commit stops; a newer release exists, so it stops as superseded; a release missing while the tag exists.
- Local, for `publish-plan.sh`: each guard refuses on its own failing case, including a presser with Write only, a PR head that matches no `draft-commit` artifact, an artifact from a run on another branch, and no artifact. A matching artifact from a `pull_request` run whose fork branch is named `main` is refused. A draft followed by a dry run still passes.
- After merging, before any real run: a dry run of each workflow on `main` shows the tag and notes, and creates nothing.
- Two dry runs started together on `main`: the second waits for the first.
- The first real "Publish update", on the first draft from Phase 4. Afterward confirm:
  - the tag points at the merge commit
  - the release is marked latest, with the memo as notes
  - pkgdown deployed from the tag
  - r-universe reports the new version, and the poll job passed
- The first real "Tag release" waits for the next hand-made change that needs publishing.

**Results:** (to fill in)

## Phase 6: new-data reminder

1. **`.github/workflows/new-data-check.yml`:** `schedule` (`17 14 * * 1-5`) and `workflow_dispatch` with `dry_run`. Check job with Environment `data-apis`, `contents: read`: `tar_make(names = ends_with("_raw_csv"))`, then compares the snapshots with `main`'s and writes a one-line summary as a job output. Issue job with `issues: write` and no R.
2. **`.github/scripts/update-reminder-issue.sh`:** opens, updates, or closes the one issue labeled `new-data`, mentioning `$REMINDER_MENTION`. It stays silent when nothing is new since the last notice, which it reads from the issue body.
3. **Stale manual inputs:** the check job also runs the memo's stale-input function and adds its warnings to the summary.

**Verification:**

- Local, with a stand-in `gh`: new issue; update with a comment; nothing new, no change; `main` caught up, issue closed.
- After merging: a dry run; then the first scheduled run after new data. The mention notifies both maintainers (design, "To verify").

**Results:** (to fill in)

## Phase 7: documentation

1. **README.Rmd:** how updates work, in short (the click table from the design); that r-universe serves releases and `main` can be ahead; and a "Maintainer setup" section with the team, rulesets, Environment, variable, and the r-universe setting.
2. **`AGENTS.md`:** the workflows, what each script does, and that the API-key jobs can only run from `main`.
3. **`.roborev.toml`:** update the guidelines if the phases changed anything they describe.
4. Mark this plan done, with a summary of what changed from the plan as built.

**Results:** (to fill in)

## Phase 8 (later): offline rebuild check

As the design describes: clean from the committed snapshots instead of the fetched data, add an offline `targets` project, and add a step to `check.yml` that rebuilds offline and fails if `data/` or `data-raw/processed/` differ from the committed files. Planned in detail when it starts.

## Open questions

1. **One check or three?** This plan replaces `R-CMD-check.yaml` and `README.yaml` with one `check.yml`, so the ruleset requires a single check named `check`. The alternative keeps the r-lib workflows and requires each by name. One check is simpler to require and to call from the publishing workflows.
2. **`test-data-currency.R`:** the FRED verification in Phase 1 does the same job, better (24 months, four series, failing loudly in "Draft update"). Remove the old test, or keep it as a local convenience?
3. **Known missing months:** `bls_missing` sits in `data-raw/_targets.R`. The consistency tests need the same list but can't read pipeline code, since `data-raw/` isn't in the built package. Options: an internal dataset (`R/sysdata.rda`) written by the pipeline, or a short list duplicated in the test with a comment pointing to the pipeline. I lean toward the internal dataset.
4. **r-universe poll limit:** 3 hours, checking every 5 minutes. r-universe usually rebuilds within an hour of a release, but I haven't measured it for this universe. OK as a starting point?
5. **Timing:** the October CPI comes out around November 12. Phases 0 to 3 can likely be done before then, but "Draft update" (Phase 4) probably can't. The November update would then follow the manual routine. Is that acceptable, or should Phase 4 be squeezed in first?
