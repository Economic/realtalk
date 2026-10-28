# Implementation plan: calendar downloads from GitHub Actions

Date: 2026-10-28
Status: investigating.
Branch: `fix-calendar-downloads`; prepare a PR to `main`, do not merge or publish
without the maintainer's instruction.

## Goal

Make Calendar refresh download both official feeds on a GitHub runner. PR #49
is merged, its main check passed (40712438351), and the saved calendar was
initialized locally with 32 future events. The daily starter dry run passed
(40712762298). The calendar refresh dry run failed twice with HTTP 403
(40712451202), although the identical Python downloader works locally.

## Decisions so far

- Keep the Monday 05:17 and daily 10:17 Eastern schedules and the official BLS
  ICS and BEA JSON sources. Preserve the saved calendar on failure.
- First identify the refusing source and compare ordinary HTTP clients and
  headers on GitHub itself. Use a temporary branch-only, read-only diagnostic
  workflow; no API keys, write permissions, package build, or calendar writes.
- Prefer one small transport fix demonstrated on a runner, with useful error
  messages naming the failed URL. Keep the successful parsing and validation.
- Remove the diagnostic workflow before opening the final PR. Verify the real
  Calendar refresh workflow with `dry_run=true` on the implementation branch.
- Use the repository secret `BLS_DOWNLOAD_EMAIL` for the BLS calendar User-Agent,
  passed only to the read-only download step. The user chose this secret after
  the email User-Agent succeeded on the standard runner.
- If a solution needs a different data source, proxy, persistent browser,
  runner architecture, or new credentials, stop and ask the maintainer. Do not
  silently add fallback chains or change the agreed scheduling design.

## Accepted risks

- Occasional agency/network failures still fail visibly and preserve the last
  schedule. This fix does not add retries or promise uninterrupted access.
- Official calendar format changes and same-week release changes retain the
  prior plan's accepted risks. Do not reopen them during transport work.
- Keep reviews focused on ordinary download failures. Avoid mechanisms for
  speculative race, attacker, or recovery scenarios.

## Implementation and verification

1. Commit this plan and run the design panel. Run a branch-only GitHub probe
   comparing the current Python downloader with curl and minimal header/URL
   variants; record response status, source, body type, and short public error
   excerpts. Do not print environment variables or credentials.
2. Apply the smallest successful fix, add meaningful offline tests for changed
   behavior, and run all offline automation tests and workflow linting. Use a
   real branch dry run to verify both downloads and the combined schedule.
3. Remove the probe, inspect per-commit reviews, and run the checkpoint panel.
   Triage with the accepted risks; no further review rounds for narrower cases.
4. Update maintainer guidance only if needed. Push and open a PR, await checks,
   and ask the maintainer when ready. This is workflow tooling only; no pipeline
   code, dataset, package version, tag, or release changes are intended.

## Results

- Initial Ubuntu runner probe (40716618214) received BLS HTTP 403 across Python,
  curl, browser headers, and URL variants. BEA returned HTTP 200.
- Email User-Agent probe (40718667365, commit `c646e10`) compared the same Python
  requests on `ubuntu-24.04`, keeping `Accept: */*` identical. BLS returned HTTP
  403 with `User-Agent: Mozilla/5.0` and HTTP 200 (`text/calendar`, 80,672 bytes)
  with `User-Agent: realtalk calendar bzipperer@epi.org`. BEA returned HTTP 200
  with both headers. The user supplied and requested testing this email header.
- No alternative runner is needed for this result. The uncommitted alternative
  runner probe was saved to `/tmp/realtalk-probe-before-email.patch` before
  narrowing the probe to standard Ubuntu for this comparison.
- Production downloader changes and the real Calendar refresh dry run remain
  pending; this establishes a successful transport for the next phase.
