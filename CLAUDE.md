# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`realtalk` is an R data package providing US price index datasets (CPI-U, C-CPI-U, CPI-U-RS, CPI-U-X1, PCE) and federal minimum wage data. It has one exported function: `get_price_index()`.

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
