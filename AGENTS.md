# AGENTS.md

Guidance for coding agents working in this repository.

## What this is

`realtalk` is an R data package providing US price index datasets (CPI-U, C-CPI-U, CPI-U-RS, CPI-U-X1, PCE) and federal minimum wage data. It has one exported function: `get_price_index()`.

## Working here

- **Plans:** the newest dated file in `plans/` is the current plan. Its "Decisions so far" and "Accepted risks" sections are settled: don't reopen them without a new argument. New plans go in `plans/YEAR-MM-DD-short-description.md`.
- **Changes:** make each change on a branch and open a pull request, merged with a merge commit. Ask the maintainer when a PR is ready.
- **Publishing:** merging to `main` publishes nothing. r-universe builds the latest GitHub release (`"branch": "*release"` in `economic.r-universe.dev`), so creating a release is what publishes. Never create a tag or release without being asked.
- **Commits:** commit early and often. Give each self-contained change its own commit; small commits get faster, more focused reviews.
- **Conventions:** follow the rules in `.claude/rules/`:
  - `r_package.md`: package development, documentation, and tests
  - `r_targets.md`: the targets pipeline in `data-raw/`
  - `r_analysis.md`: general R style
- **Live data:** `tar_make()` calls the BLS and BEA APIs and changes the committed data. Don't run a full one without a reason; scope it with `tar_make(names = ...)` where you can.

## Reviews (roborev)

- A post-commit hook sends every commit to one code reviewer automatically. See the results with `roborev list` and `roborev show <job>`. Only commits made locally are reviewed, not commits pulled from `main`.
- At the end of each plan phase, run `roborev review --branch --base main --panel checkpoint_panel --wait`. That panel covers code, design, and security. Run `--panel design_only_panel` on a new plan.
- `.roborev.toml` tells reviewers what matters here: wrong published values, calculation changes nobody declared, breaking changes to `get_price_index()`, and the security of the GitHub workflows. Fix real findings. For a finding that needs several unusual conditions at once, record it as an accepted risk in the current plan rather than adding code. Then close the job with `roborev comment <job> "..."` and `roborev close <job>`.

## Common commands

```bash
# Package development
Rscript -e "devtools::document()"
Rscript -e "devtools::test()"
Rscript -e "devtools::check()"
Rscript -e "pkgdown::check_pkgdown()"

# Data pipeline (uses _targets.yaml to find data-raw/_targets.R)
Rscript -e 'targets::tar_make()'
```

## Architecture

- **R/**: Package source — roxygen2 documentation for datasets plus `get.R` (the sole exported function `get_price_index()`)
- **data/**: 23 `.rda` dataset files built by the data pipeline
- **data-raw/**: Targets-based pipeline that fetches data from BLS and BEA APIs, processes it, and writes `.rda` files via `usethis::use_data()`
  - `_targets.R` + `packages.R`: pipeline definition and dependencies
  - `R/`: processing functions (fetchers, helpers, per-index logic)
  - `raw/` and `processed/`: intermediate data files

## API keys

The data pipeline requires `BLS_API_KEY` and `BEA_API_KEY` environment variables. These are in `.Renviron` (which is denied from reading by Claude settings).

## Versioning

Version scheme is `YYYY.M.DD`, updated with each data refresh. Document changes tersely in `NEWS.md`.

## pkgdown

Uses `epitemplate` as the pkgdown template. Site config is in `_pkgdown.yml`. New documentation topics must be added there.
