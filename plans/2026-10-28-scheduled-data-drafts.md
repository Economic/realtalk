# Implementation plan: scheduled data drafts

Date: 2026-10-28
Status: implementation complete; PR #49 opened. Workflow startup verification
remains for after merge.
Issue: https://github.com/Economic/realtalk/issues/48
Branch: `issue-48-scheduled-drafts`; one implementation PR to `main`, merged only
after the maintainer says to merge. No tags or releases.

## Goal

Prepare data update PRs automatically after BLS and BEA releases. Keep calendar
refreshes separate from data checks, preserve approvals when nothing changed,
and retain the manual Draft update button and all publish gates.

## Decisions so far

- Refresh the calendar every Monday at **05:17 America/New_York**. Fetch BLS's
  `https://www.bls.gov/schedule/news_release/bls.ics` and BEA's
  `https://apps.bea.gov/API/signup/release_dates.json`. BEA also provides
  `https://www.bea.gov/news/schedule/ics/online-calendar-subscription.ics`;
  use JSON for its simple grouping by release name, without a second fallback.
- Select Consumer Price Index, Gross Domestic Product, and Personal Income and
  Outlays releases. Save all available upcoming dates and their release times,
  with a refresh timestamp. Validate both sources before replacing anything.
- Store `schedule.json` on a dedicated `calendar` branch. A successful calendar
  refresh commits that file there; it never changes `main` or `data-update`.
  A failed refresh notifies maintainers and leaves the last saved schedule intact.
- Run a small starter every day at **10:17 America/New_York**. Read the saved
  schedule as data, without checking out or executing code from `calendar`.
  Run Draft update if a selected release is due today and its time has passed.
  Multiple releases on one day cause one build, which fetches all sources.
- Also rebuild an existing data PR when its parent commit differs from current
  `main`, even on a day without a release. Code merged into `main` thus reaches
  the next daily draft run. With no open data PR, code-only releases still use
  Tag release; an unchanged rebuild does not create a data PR.
- Reuse Draft update through `workflow_call`, with an `automatic` boolean.
  The existing manual button retains its deliberate refresh behavior.
  Automatic runs leave an open PR alone if its processed data and parent commit
  match the new build. Do not compare serialized `.rda` bytes, version dates,
  or generated NEWS to decide that unchanged data needs another review.
- Preserve the one bot commit on top of `main`, full checks and FRED verification,
  the read-only build/write-only-without-R job split, and maintainer-controlled
  publishing. Automatic drafts identify themselves and do not assign the user
  who happened to last edit the schedule as though they pressed the button.
- Keep New data check available manually as a diagnostic/reminder; replace its
  Friday schedule with the daily starter. No second automatic reminder system.
- Support manual calendar refresh and dry runs. Real calendar writes use `main`;
  dry runs can test a branch. Bootstrap by running Calendar refresh after merge,
  before relying on daily runs. Missing, invalid, or exhausted saved schedules
  produce a visible failure, not a false "no release" result.
- Do not add automatic publishing, retry queues, calendar fallback chains,
  workflow-file rewriting, new repository secrets, or ruleset changes.

## Accepted risks

- A release changing within its own week after Monday's refresh is unlikely in
  practice. The daily job follows the saved dates until the next successful
  refresh. Maintainers can refresh manually or press Draft update.
- GitHub can delay or drop scheduled runs. The five-hour Monday buffer and the
  retained schedule are sufficient; no external scheduler or locking protocol.
- The agency APIs or FRED may not be ready at 10:17. A failed draft leaves the
  existing PR intact; rerun Draft update manually. No additional automatic
  retry cadence is included in this change.
- An agency API could rarely return old data at 10:17 instead of failing.
  That run can succeed without creating or changing a draft; there is no
  additional notification or next-day attempt. The maintainer explicitly
  accepted this on 2026-10-28: at that time, new data or a failure is overwhelmingly
  more likely. Use Draft update manually if necessary.
- A failed Monday refresh may keep old dates for several weeks; it must visibly
  notify maintainers. Save the available future horizon rather than only a week.
  If that horizon runs out, report a failure and use the manual buttons.
- A maintainer publishing while a new draft is being built, or two people
  changing branches at once, remains covered by the prior plan's accepted races.
  Do not add provenance records, new locks, or special recovery protocols.
- A code-only change with no data PR waits for manual Draft update or the next
  release day; publishing a code-only change uses Tag release as before.
- Calendar parser support is limited to the formats the official feeds use,
  including folded ICS lines, UTC and TZID times, and cancelled events. Invalid
  or unexpectedly empty relevant results fail the refresh. Do not build a
  general-purpose iCalendar engine.
- Review guidance: prioritize simplicity and usefulness. Fix plausible normal
  failures and wrong-value or publish-gate bugs. Record narrow edge cases here;
  do not add mechanisms solely to satisfy speculative review findings.

## Phase 1: plan and design review

1. Commit this plan and run the `design_only_panel` against the branch.
2. Triage findings using the accepted risks above. If a design question needs a
   maintainer decision, stop implementation and ask; do not silently choose.

### Results

Design panel job 550 passed with no findings. The plan commit's review (548)
also passed. Subagents inspected the proposed interfaces before editing.
Both agency feeds can be downloaded locally using explicit User-Agent and
Accept headers; no fallback source or GitHub probe workflow is needed.
The planning checkpoint raised the old-data/no-op case. Implementation paused
for the maintainer's decision, and the maintainer accepted that risk with no
retry or notification mechanism. The decision was recorded on checkpoint job
555, which was closed after the documentation update.

## Phase 2: implementation with subagents

Delegate separate file ownership, then inspect and integrate their work:

1. **Calendar logic:** a small Python 3 standard-library utility under
   `.github/scripts/` downloads/parses/validates the feeds, writes normalized
   JSON only after success, and determines whether today's release is due.
   Add offline fixtures/tests for the actual formats, Eastern date boundaries,
   both-source validation, and preserving an existing output on failed refresh.
2. **Draft behavior:** extend `update-draft-pr.sh` with `AUTOMATIC=true|false`
   (default false). Skip replacing an automatic draft only when processed data
   and the parent commit both match. Keep manual refresh and no-data closure.
   Add local-git tests with a stand-in `gh` for unchanged automatic runs, changed
   values, changed main, manual refresh, new PR, and data already on main.
3. **Workflow integration:** add Calendar refresh (read-only parsing job;
   separate writer/notification jobs without R), a narrowly scoped shell writer
   for `calendar`, and a daily starter reading the saved schedule. Add the
   reusable Draft update entry point. Preserve explicit permissions, pinned
   actions, main-only real runs, dry runs, and draft concurrency.
4. Parent agent reviews all files, connects automated tests to the required
   check, and updates `.github/MAINTAINING.md` and `AGENTS.md`. Workflow-only
   changes need no package version bump or release.

File organization refinement: keep New data check manual-only, and put the
daily gate in `scheduled-data-update.yml`. Separate workflows avoid conditional
reminder-versus-drafting behavior while keeping the agreed schedule and buttons.

### Results

Three implementation subagents completed the calendar utility, draft behavior,
and workflow integration with separate file ownership. The parent inspected
all changes and reran their tests. Calendar and draft agents cross-reviewed
the other components; both found no normal-path defects or design issues.

- `release-calendar.py` uses Python's standard library and the two official
  feeds; the saved file is validated before replacement.
- `calendar-refresh.yml` saves dates in a separate job and reports refresh
  failures through one rolling issue mentioning the maintainers.
- `scheduled-data-update.yml` calls the reusable Draft update workflow; the
  previous reminder remains manual-only.
- Automatic unchanged drafts preserve their commit, PR text, and approval;
  manual runs retain deliberate refresh behavior.
- Documentation describes initialization, accepted risks, and manual recovery.

## Phase 3: verification and PR

- Run meaningful offline calendar and local-git draft/writer tests. Include
  workflow syntax checks; use actionlint if available with timezone support.
- Read every job's permissions and the artifacts/file copies. Confirm no job
  runs R/package code with a write token and no calendar branch code executes.
- Run the package tests and pipeline function tests; no live `tar_make()` is
  needed unless implementation changes pipeline code. Keep committed data intact.
- Probe the two official feed downloads read-only. BLS returned 403 locally
  during brainstorming; test from a GitHub runner with a branch-only dry-run
  probe if necessary. Do not hide an inaccessible feed behind fallback logic.
- Review each subagent's diff and test results. Commit self-contained changes;
  inspect hook reviews. Run `roborev review --branch --base main --panel
  checkpoint_panel --wait` at the implementation checkpoint, triage, comment,
  and close resolved jobs. Do not iterate on increasingly rare edge cases.
- Push the branch and open a PR with validation and remaining deployment checks.
  The PR check must pass. Ask the maintainer when it is ready; do not merge.
- After merging (later, with maintainer authorization), dry-run Calendar refresh,
  initialize `calendar`, and dry-run the daily starter. These checks cannot
  fully run on new workflow_dispatch files before they reach the default branch.
  Do not run a publishing workflow or create a tag/release.

### Results

- Offline automation tests: **28 passed**, including real local git branch and
  draft history tests and a stand-in GitHub CLI for notification/PR writes.
- Existing package tests: **90 expectations passed**; pipeline function tests:
  **48 expectations passed**.
- actionlint **1.7.12**, shell syntax checks, and `git diff --check` passed.
  The downloaded actionlint binary was checked against its release checksum.
- Live read-only calendar refresh to `/tmp`: **32 upcoming events**, including
  CPI through December 10, 2026 and BEA releases through December 2027.
- No `tar_make()` was run: no pipeline code changed, and no data refresh is
  needed to verify these workflow changes. Committed data is unchanged.
- No remote calendar branch, scheduled data draft, tag, or release was created.
  Initialization and real scheduled workflow behavior remain post-merge checks.
- GitHub `check` (run 40705916333) and `pkgdown` (run 40705916276) both passed
  for the implementation commits. They passed again for the accepted-risk
  clarification (`check`: 40706787176; `pkgdown`: 40706786840).
- Per-commit reviews of the draft, calendar, and workflow implementation (557,
  559, 561) passed. Final checkpoint: job 568. Its review results and the latest
  GitHub checks are tracked on PR #49: https://github.com/Economic/realtalk/pull/49.
- `roborev insights --branch issue-48-scheduled-drafts --since 7d` found no
  failing reviews to analyze, so no review-guideline changes were needed.
