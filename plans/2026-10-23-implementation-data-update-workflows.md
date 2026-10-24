# Implementation plan: button-driven data updates

Date: 2026-10-23
Status: simplified 2026-10-23 (see the design's "Accepted risks"); ready for review

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
- From Phase 3 on, merging needs a maintainer's approval: the other maintainer approves Ben's PRs, or Ben uses the admin bypass.

### Testing the workflows

- The R functions are tested locally, with the keys from `.Renviron`, and with fixtures for failure cases.
- The shell scripts are tested locally with a stand-in `gh` that logs its calls, as in productivity_pay_gap's Phase 6.
- GitHub starts a `workflow_dispatch` workflow only once its file exists on the default branch. So each button workflow ("Draft update", "Publish update", "Tag release", the reminder) is first run after its PR merges, as a dry run, before any real run. After that, dry runs can also be started from a branch, to test changes before merging them. Merging a button workflow is safe: it does nothing until a maintainer presses it. The PR check is triggered by `pull_request`, so it runs on its own PR before merging.

## Before Phase 0: review harness (done 2026-10-22)

PR #34: `.roborev.toml`, `AGENTS.md`, the design, and its design review. Economic/economic.r-universe.dev#2 added `"branch": "*release"`.

## Phase 0: feasibility checks

Settings and spikes that later phases depend on. Throwaway workflows go on `spike/*` branches and are deleted afterward.

1. **r-universe sync.** Confirm `https://economic.r-universe.dev/api/packages/realtalk` reports the release, not `HEAD` (it read `RemoteRef: HEAD` on 2026-10-23). Record the field names the poll step in Phase 5 will read.
2. **Repository secrets.** Add `BLS_API_KEY`, `BEA_API_KEY`, and `FRED_API_KEY`.
3. **One spike workflow** on a `spike/*` branch, triggered by a push to it:
   - reports whether each key is set, never its value, and makes one small BLS, BEA, and FRED call
   - calls `GET /repos/{owner}/{repo}/collaborators/{actor}/permission` with `github.token` and prints `role_name` for the person who pushed
   - installs the pipeline's packages (see Phase 1, step 2) on `ubuntu-24.04` and loads them. Record the time and any missing system libraries, as productivity_pay_gap found with `libglpk`.
4. **Access review.** Check that the repo's Admin roles are intended (design, "To verify").

**Exit criteria:** the keys work from CI; the role lookup works with the built-in token; the pipeline's packages install on the runner.

**Results (2026-10-23):**

- **r-universe:** it synced the registry at 13:47 UTC (commit "Sync registry" in `r-universe/economic`, whose `.gitmodules` shows `branch = *release` for realtalk), and it has built nothing since, though #34, #35, and #36 merged to `main`. The API's `RemoteRef: HEAD` and `RemoteSha` describe the last build (v2026.10.14), not the setting. The poll in Phase 5 reads `Version`.
- **Secrets and team:** the repository secrets and the `realtalk-maintainers` team were set up by Ben. The repo's Admin roles are intended.
- **Spike** (runs 40031111574, 40031650572, and 40032329169 on `spike/phase-0`, now deleted):
  - the built-in token reads the presser's role: `role_name=admin permission=admin`
  - all three keys are set. Through `epidatatools`, BLS returned 9 rows, BEA 248, and FRED 3.
  - the pipeline's packages install and load on `ubuntu-24.04`. `setup-r-dependencies` with `needs: check, readme, pipeline` took about 3.5 minutes. No missing system libraries.
  - **BEA was inconsistent.** The second run's `get_bea_nipa()` failed because BEA returned an error instead of data. In the third run, a direct call with the same key got "This UserId is not active", and `get_bea_nipa()` then succeeded. A failed BEA call stops "Draft update" visibly, and a rerun repairs it.

## Phase 1: pipeline changes (local)

1. **Stop committing `_targets/meta/meta`.** Change `data-raw/_targets/.gitignore` to ignore everything but itself, and `git rm --cached data-raw/_targets/meta/meta`.
2. **Declare the pipeline's packages.** Add `Config/Needs/pipeline:` to `DESCRIPTION`, listing what `data-raw/packages.R` loads (`targets`, `tarchetypes`, `tidyverse`, `readxl`, `economic/epidatatools`, `economic/epitargets`, `tsibble`, `cli`, `assertr`, `conflicted`, `usethis`, plus `desc` and `gert` if steps 5 and 6 use them). CI installs them with `setup-r-dependencies` and `needs: pipeline`.
3. **Consistency tests**, in `tests/testthat/test-data-consistency.R`. They read the package's own datasets, need no network, and so run in R CMD check, in the PR check, and in r-universe's own check. Each check from the design's "Internal consistency checks" gets its own test, and each test is first shown to fail on deliberately broken data:
   - no gaps apart from the known missing months. The pipeline and the test read the list from one place: the pipeline writes it as the package's internal data (`R/sysdata.rda`, object `known_missing_months`, not exported), and `data-raw/_targets.R` and the test both use it. Today the list is `bls_missing` in `data-raw/_targets.R`.
   - no duplicate periods, in every dataset
   - extended C-CPI-U against C-CPI-U from 2000, by frequency: monthly NSA and annual within 0.05, quarterly NSA within 0.1, skipping known missing months and the quarters that contain them
   - annual and quarterly price index values only for complete periods, counting a known missing month as present; not applied to the minimum wage
4. **The memo**, as a `change_memo` target in `data-raw/R/memo.R`. It writes `reports/change_memo.md` (`reports/` ignored by git and `.Rbuildignore`).
   - **Baseline:** the highest `v*` tag, by R's version ordering, or `REALTALK_BASELINE` if set. That's the latest release, except in the middle of a failed publish, which doesn't matter for a memo. It needs only `git`, so it works the same locally and in CI. Baseline files come from `git show <ref>:data-raw/processed/<name>.csv`.
   - **Sections:** coverage, revisions (with expected and unexpected labels), verification, stale manual inputs, and check results, as in the design. Each section is a function that returns a small table, and one function assembles the Markdown, as productivity_pay_gap's `R/report.R` does.
   - **Unexpected revisions:** a separate function, `find_unexpected_revisions(baseline, current)`, returns changed historical CPI-U NSA values and changed final C-CPI-U values. The memo lists them, and the PR check fails on them (Phase 2), with the same baseline.
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
7. **Remove `tests/testthat/test-data-currency.R`.** The FRED verification in step 5 replaces it: 24 months instead of the latest value, four series instead of three, and it fails "Draft update" instead of skipping silently without a key.

**Verification:**

- `tar_make(names = c(change_memo))` with `REALTALK_BASELINE=v2026.9.11` against the v2026.10.14 working tree: the memo shows CPI-based data through September 2026, PCE through August 2026, PCE revisions labeled expected, and no unexpected revisions.
- The same with the baseline at `HEAD`: the memo reports no changes.
- A copy of the data with one historical CPI-U NSA value changed: `find_unexpected_revisions()` returns it.
- The real v2026.7.14 to v2026.8.12 transition: `find_unexpected_revisions()` returns nothing, though 11 C-CPI-U months were revised. A copy of v2026.8.12 with June 2025 C-CPI-U changed (final in the v2026.7.14 vintage) returns that month.
- `fred_verification` passes on today's data with the key, records "not run" without it, and fails with `REALTALK_REQUIRE_FRED=true` and no key. A fixture with one value changed fails with a message naming it.
- `devtools::test()` and `devtools::check()` pass. Each consistency test fails on its broken-data fixture.
- `next_version()`: today's date; a same-day suffix; a date in daylight saving time and one not.
- Run `tar_make()` scoped to the changed targets, as `.claude/rules/r_targets.md` requires, and confirm no committed data changes.

**Results (2026-10-23):**

- **Built:**
  - `data-raw/_targets/meta/meta` is no longer committed.
  - `Config/Needs/pipeline` in `DESCRIPTION`.
  - `R/sysdata.rda` holds `known_missing_months`, written by the `known_missing_months_out` target from `bls_missing`.
  - `tests/testthat/test-data-consistency.R`, with its checks in `helper-data-checks.R`.
  - `fred_verification` (`data-raw/R/verify.R`) and `change_memo` (`data-raw/R/memo.R`) targets.
  - `data-raw/R/update.R` and `data-raw/prepare_update.R`.
  - `test-data-currency.R` removed, with `epidatatools` dropped from `Suggests` and `Remotes`.
- **Memo against v2026.9.11:** September CPI added, PCE revised from 2021 (largest: July 2026, 131.659 to 131.172), no unexpected revisions. Against `HEAD`: "No changes".
- **Unexpected revisions:** the real v2026.7.14 to v2026.8.12 transition returns nothing. Planted changes to June 2025 C-CPI-U (final in that vintage), March 1990 CPI-U NSA, and a removed CPI-U NSA row are each returned. A planted change to July 2025 C-CPI-U (interim) isn't. A ref like `$(touch …)` runs nothing, because git arguments are quoted.
- **FRED:** all four series match for the latest 24 months (2024m9 to 2026m9, PCE to 2026m8). A planted PCE value fails with a message naming it. Without a key, it records "not run"; with `REALTALK_REQUIRE_FRED=true` and no key, it fails.
- **Consistency tests:** 67 expectations pass, including each check failing on deliberately broken data.
- **`next_version()`:** `2026.10.23`; `2026.10.14.1` and `.2` on the same day; `2026.2.13.1` against the zero-padded `v2026.02.13`. `today_eastern()` turns 03:30 UTC on July 1 into June 30, and 04:30 UTC on December 1 into November 30. `prepare_update.R` changes only the `Version` line and adds the NEWS entry.
- **Full `tar_make()`:** the processed CSVs were unchanged. Every `.rda` differed byte for byte but held identical objects: `.rda` files record the R version that wrote them. So a draft PR will show every `.rda` as changed. That's why "Draft update" decides on `data-raw/processed/`, not `data/`.
- **Checks:** `devtools::check()` 0 errors, 0 warnings, 0 notes; `pkgdown::check_pkgdown()` no problems.
- **Departures from the plan:**
  - The memo has no "check results" section. The memo target runs before R CMD check, so "Draft update" will append the check results to the PR body (Phase 4).
  - The stale-input warning for the minimum wage checks whether the monthly series reaches the current year (`final_year` in `data-raw/R/fed_mw.R` is hard-coded to 2026), not the file's age. The federal minimum wage hasn't changed since 2009, so a file-age warning would fire every month.
  - Git is read with `system2()` and quoted arguments, not `gert`.
  - The pipeline's functions got their own tests, `data-raw/tests/`, run with `Rscript data-raw/tests/run.R`: 37 expectations covering the unexpected-revision rule (including the 12-month boundary), the change summary, the stale-input warnings, the FRED verification with a stand-in fetch, `next_version()`, `today_eastern()`, and `news_entry()`. The ad hoc checks above became these tests.
  - The memo target now also depends on the minimum wage exports, which aren't in the catalog (per-commit review job 302).
  - The local roxygen is 8.1.1 and the repo was built with 7.3.3. `devtools::document()` would change `DESCRIPTION` and `man/realtalk-package.Rd`, unrelated to this phase, so those changes are left out.

## Phase 2: the PR check and pkgdown

1. **`.github/workflows/check.yml`**, one job named `check`, on `ubuntu-24.04`, triggered by `pull_request` to `main`, `push` to `main`, `workflow_dispatch`, and `workflow_call` with a `ref` input. No secrets; `contents: read`.
   - check out `ref` (or the event's commit) with full history and tags, for the revision check, and `persist-credentials: false`
   - install the dependencies with `r-lib/actions/setup-r-dependencies`: the package's own, `needs: check, readme, pipeline` (`Config/Needs/readme` lists `tidyverse` and `hrbrthemes`), and `extra-packages: any::rcmdcheck, any::devtools, local::.`, as the current `R-CMD-check.yaml` and `README.yaml` do between them
   - R CMD check, with the tests, including the consistency tests
   - the pipeline's own tests: `Rscript data-raw/tests/run.R` (added in Phase 1, after per-commit review jobs 300, 302, and 304)
   - fail if the README is stale: `devtools::build_readme()`, then `git diff --exit-code -- README.md`
   - fail on unexpected revisions: run `find_unexpected_revisions()` against the baseline (the highest `v*` tag)
   - write to the job summary that FRED wasn't checked here
2. **Replace `R-CMD-check.yaml` and `README.yaml`** with `check.yml`, so one check named `check` can be required. Update the README badge.
3. **`pkgdown.yaml`:**
   - on pull requests: build only, as now
   - on `workflow_dispatch` with a `ref` input: check out that ref, build, and deploy. "Publish update" and "Tag release" pass the release tag.
   - on `release: published`: build the release's tag and deploy. A release created by a person still triggers this, which covers the manual routine until the buttons exist.
   - no deploy on pushes to `main`
4. **Pin actions** to commit SHAs with the version in a comment, as productivity_pay_gap does, and set `permissions` per job.

**Verification:**

- This phase's own PR: `check` passes.
- A throwaway PR that changes `README.Rmd` without rebuilding: `check` fails on the README step. On this phase's own PR, the README rebuild succeeds on a clean runner, which shows the readme dependencies install.
- A throwaway PR that changes one historical CPI-U NSA value in `data-raw/processed/` and `data/`: `check` fails on the revision step and names the value.
- A throwaway PR that breaks a consistency rule: `check` fails in the tests.
- After merging: a manual pkgdown run with `ref` set to `v2026.10.14` deploys the site from that tag.

**Results (2026-10-23):**

- **Built:**
  - `.github/workflows/check.yml`: R CMD check, `data-raw/tests/run.R`, the stale-README check, and `data-raw/check_revisions.R`
  - `R-CMD-check.yaml` and `README.yaml` removed, and the README badge points at `check`
  - `pkgdown.yaml` deploys only for a published release or a `workflow_dispatch` with a tag
  - actions pinned to commit SHAs: `actions/checkout` v7.0.1, `r-lib/actions` v2.14.0, and `JamesIves/github-pages-deploy-action` v4.9.0
- **PR #37** (this phase): `check` passed.
- **PR #38** (README.Rmd changed without rebuilding): R CMD check and the pipeline tests passed, then `check` failed at the README step (run 40031343266).
- **PR #39** (March 1990 CPI-U NSA changed to 999 in `data-raw/processed/` only): R CMD check, the pipeline tests, and the README step passed, then `check` failed at the revision step with "1 unexpected revision since v2026.10.14", naming `cpi_u_monthly_nsa 1990m3` (run 40031349650). The baseline tag was found, so `fetch-depth: 0` brings the tags.
- **Not run:** the plan's third throwaway PR, a broken consistency rule. The consistency tests already show each check failing on broken data, and they run inside R CMD check.
- **Slow runners:** `setup-r` took about 17 minutes on #37 and #38 and about 1 minute on #39, all started within the same minute. It's the step that downloads R, and it also hung on PR #35 earlier the same day. If it keeps happening, pinning an R version would let `setup-r` use its cache.
- **Checkpoint review** (job 340): no findings.
- **After merging:** a manual pkgdown run with `ref` set to `v2026.10.14` checked out that tag ("HEAD is now at 91bde98 v2026.10.14"), built the site, and deployed it (run 40051999869).

## Phase 3: team, rulesets, and settings

Mostly GitHub settings, recorded here and in the README's maintainer section (Phase 7). The repo change is `CODEOWNERS`.

1. **Team `realtalk-maintainers`** in the Economic org: visible, two members, Maintain role on realtalk. May need an org owner; Ben as team maintainer.
2. **`.github/CODEOWNERS`:** `* @economic/realtalk-maintainers`.
3. **Ruleset "protect main"** and **ruleset "require check on main"**, exactly as the design's "Roles and repository settings" lists, with the `check` job from Phase 2 as the required check.
4. **Repository variable** `REMINDER_MENTION` = `@economic/realtalk-maintainers`, for Phase 6.

**Verification**, with throwaway PRs closed afterward:

- A direct `git push` to `main` is rejected.
- A PR approved by a non-maintainer can't merge; approved by a maintainer, it can.
- After approval, a new commit on the PR dismisses the approval.
- The admin bypass lets Ben merge his own PR without approval, but not with a failing `check`.
- Requesting a review from the team notifies both members.

**Results (2026-10-23):**

- **Rulesets:** created by Ben in Settings, because the local `gh` token lacks the Administration permission to create them through the API. Read back through the API, they match the design. GitHub added `require_extra_approval_for_unattributed_changes: true` on its own; its effect on the bot's draft PRs is checked in Phase 4.
- **`CODEOWNERS`:** PR #40, merged by Ben with the admin bypass and no approval. So the bypass for pull requests works. At first GitHub rejected the line ("Unknown owner… make sure the team exists, is publicly visible, and has write access"), because the team had no access to realtalk yet, so no review was requested on #41. After Ben gave the team the Maintain role, `GET /repos/Economic/realtalk/codeowners/errors` reported no errors.
- **A direct `git push` to `main`** of an empty commit: "push declined due to repository rule violations", naming the required `check`.
- **The `REMINDER_MENTION` variable:** to be set by Ben in Settings, for the same token reason.
- **Not tested here:**
  - a non-maintainer's approval not counting: needs a Write user outside the team
  - a new commit dismissing an approval: the first re-draft in Phase 4 shows it
  - the team being notified of a review request: the first PR after #40 shows it

## Phase 4: Draft update

1. **`.github/workflows/draft-update.yml`** (`workflow_dispatch`, `dry_run` input), as the design describes:
   - **build job:** the API keys, `contents: read`. A real run refuses unless `github.ref` is `refs/heads/main`; a dry run can run from any branch. It installs the same dependencies as `check.yml`, then runs `tar_make()` with an empty store and `REALTALK_REQUIRE_FRED=true`, then `data-raw/prepare_update.R`, `devtools::build_readme()`, and R CMD check. It writes the memo to the run summary and uploads the changed files as an artifact.
   - **PR job:** `contents: write`, `pull-requests: write`, `issues: write` (for the assignee), no R. It runs after every successful build that isn't a dry run.
2. **`.github/scripts/copy-draft-files.sh`:** copies only regular files at allowlisted paths from the artifact: `data/*.rda`, `data-raw/processed/*.csv`, `data-raw/raw/snapshots/*.csv`, `DESCRIPTION`, `NEWS.md`, `README.md`, `man/figures/README-*.png`, and `reports/change_memo.md`. Adapted from productivity_pay_gap's `copy-refresh-files.sh`.
3. **`.github/scripts/update-draft-pr.sh`** compares the fresh `data-raw/processed/` files with `main`'s:
   - **the same:** `main` already has this data. Close any open draft PR with "`main` already has these numbers", and stop.
   - **different:** build `data-update` from the build's commit, commit as `github-actions[bot]`, force-push, and open the PR or update its title and body: title "Data update {version}: {coverage}", body the memo, assignee `github.actor`. `CODEOWNERS` requests the maintainers' review automatically, so the script doesn't. This happens even if the data equals the open draft's, and the push cancels any approval.

**Verification:**

- Local: `copy-draft-files.sh` against crafted artifacts (a `.git/config`, a symlink, a nested path, an unexpected file name) rejects them and copies nothing. `update-draft-pr.sh` with a stand-in `gh`: new PR; updated PR; data equal to `main` with a draft open, so the draft is closed.
- After merging, on `main`: a dry run writes the memo to the run summary and touches no branch.
- The first real run, when new data is out: it opens the PR, assigned to whoever pressed it, with the memo; the held check appears, and approving the run makes `check` pass.
- After the first draft is published (Phase 5): a run with no new data does nothing.

**Results (2026-10-23):**

- **Built** (PR #41): `.github/workflows/draft-update.yml`, `.github/scripts/copy-draft-files.sh`, and `.github/scripts/update-draft-pr.sh`.
- **Copy script, locally:** a good artifact copies all 8 files. A `.git/config`, a symlink, a nested path, an unexpected file, and a newline in a file name are each rejected, with nothing copied; the newline is escaped in the message. An artifact built from the real upload paths copies 57 files.
- **Draft script, locally,** with a bare repo standing in for `origin` and a stand-in `gh`: data equal to `main` with no draft does nothing; with a draft open it closes the draft. New data with no draft pushes one commit and opens the PR; with a draft open it edits the PR and comments. The commit's author and committer are `github-actions[bot]` even when the environment sets other git identities.
- **Checkpoint review** (job 357): the artifact uploaded all of `man/figures/`, including `logo.png`, which the copy script rejects, so every real run would have failed. Now only `README-*.png` is uploaded.
- **Dry run on `main`** (run 40054388646): the build job passed in about 2 minutes, including the fresh fetch, the FRED verification required, the version (2026.10.23 at 02:29 UTC on October 24, Eastern time), README, R CMD check, and the pipeline tests. The PR job was skipped.

## Phase 5: Publish update and Tag release

1. **`.github/scripts/tag-release.sh`**, the shared tagging logic from the design: target and version, the tag, and the release, each checking what exists first.
2. **`.github/workflows/publish-update.yml`** (`workflow_dispatch`, `dry_run`), with the jobs from the design: plan, merge, check (calls `check.yml` with the merge commit), tag, and the follow-ups (pkgdown with the tag, and the r-universe poll). Concurrency group `publish`, `cancel-in-progress: false`.
   - **`.github/scripts/publish-plan.sh`:** the guards: role, open PR, checks passed and maintainer approval on the latest commit, the branch is exactly one commit beyond its base authored by `github-actions[bot]`, `main` hasn't moved, version not released and higher, `NEWS.md` entry.
   - **The merge job:** `PUT /repos/{owner}/{repo}/pulls/{n}/merge` with `merge_method=merge` and `sha` set to the checked head, then the tree comparison.
3. **`.github/workflows/tag-release.yml`** (`workflow_dispatch` with an optional commit input, `dry_run`): the guards from the design, then `check.yml` on the target, `tag-release.sh`, and the follow-ups. Same concurrency group.
4. **The r-universe poll:** reads the version from the API every 5 minutes, and fails after 3 hours.

**Verification:**

- Local, with a stand-in `gh`, for `tag-release.sh`: a new tag and release; a rerun with both existing; a tag on another commit stops; a release missing while the tag exists.
- Local, for `publish-plan.sh`: each guard refuses on its own failing case, including a presser with Write only and a branch with a second commit pushed by hand.
- After merging, before any real run: a dry run of each workflow on `main` shows the tag and notes, and creates nothing.
- The first real "Publish update", on the first draft from Phase 4. Afterward confirm:
  - the tag points at the merge commit
  - the release is marked latest, with the memo as notes
  - pkgdown deployed from the tag
  - r-universe reports the new version, and the poll job passed
- The first real "Tag release" waits for the next hand-made change that needs publishing.

**Results (2026-10-23, local):**

- **Built:** `.github/workflows/publish-update.yml`, `.github/workflows/tag-release.yml`, and `.github/scripts/` `release-guards.sh`, `publish-plan.sh`, `tag-release-plan.sh`, `tag-release.sh`, and `poll-r-universe.sh`.
- **`publish-plan.sh`,** against a repo with a bot-authored draft on top of `main` and a stand-in `gh`: it passes when everything is in order. It refuses each of these on its own: a presser with Write; no open draft; the check failed or never ran; no approval; the version already released; a version not higher than the latest (and accepts a zero-padded older latest, `v2026.02.13`); `main` moved after the draft; a second commit pushed by hand; and a draft commit not by the bot.
- **`tag-release-plan.sh`:** passes for `main`'s merge commit; refuses a commit inside the PR (not on the first-parent history), a value that isn't a SHA, a presser with Write, and a version already released.
- **`tag-release.sh`:** a dry run writes the notes (the memo after a "Publish update" merge, the `NEWS.md` entry otherwise) and writes nothing. A real run creates the tag and the release; a rerun with both existing writes nothing; with only the tag existing, it creates the release; a tag on another commit stops it; a `TARGET` that isn't a full SHA stops it.
- **Checkpoint review** (job 368): three low findings, fixed: the plan jobs check out the dispatching branch, so branch dry runs test its scripts; the "Publish update" dry run shows the release notes; the merge step writes the full merge SHA to the run summary for recovery.
- **Mistake during testing:** a test helper ran `export` with no arguments, which printed the local shell environment, including API keys unrelated to this repo, into the session transcript. Nothing was pushed. Ben was told to rotate those keys.

## Phase 6: new-data reminder

1. **`.github/workflows/new-data-check.yml`:** `schedule` (`17 14 * * 1-5`) and `workflow_dispatch` with `dry_run`. Check job with the API keys, `contents: read`: `tar_make(names = ends_with("_raw_csv"))`, then compares the snapshots with `main`'s and writes a one-line summary as a job output. Issue job with `issues: write` and no R.
2. **`.github/scripts/update-reminder-issue.sh`:** opens, updates, or closes the one issue labeled `new-data`, mentioning `$REMINDER_MENTION`. It stays silent when nothing is new since the last notice, which it reads from the issue body.
3. **Stale manual inputs:** the check job also runs the memo's stale-input function and adds its warnings to the summary.

**Verification:**

- Local, with a stand-in `gh`: new issue; update with a comment; nothing new, no change; `main` caught up, issue closed.
- After merging: a dry run; then the first scheduled run after new data. The mention notifies both maintainers (design, "To verify").

**Results:** (to fill in)

## Phase 7: documentation

1. **README.Rmd:** how updates work, in short (the click table from the design); that r-universe serves releases and `main` can be ahead; that releases come only from the two workflows, never by hand; and a "Maintainer setup" section with the team, rulesets, secrets, variable, and the r-universe setting.
2. **`AGENTS.md`:** the workflows, and what each script does.
3. **`.roborev.toml`:** update the guidelines if the phases changed anything they describe.
4. Mark this plan done, with a summary of what changed from the plan as built.

**Results:** (to fill in)

## Phase 8 (later): offline rebuild check

As the design describes: clean from the committed snapshots instead of the fetched data, add an offline `targets` project, and add a step to `check.yml` that rebuilds offline and fails if `data/` or `data-raw/processed/` differ from the committed files. Planned in detail when it starts.

## Timing

The goal is to finish within a few days, so the November update (October CPI, mid-November) uses "Draft update" and "Publish update". If a phase slips, that update follows the current routine: update locally, merge, and create the release by hand.

## Open questions

None.
