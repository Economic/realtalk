# Cross-check the latest value of each shipped monthly price index against
# FRED. These tests run against the installed package data (data/*.rda),
# so they catch staleness, wrong-target-exported, and forgotten-to-commit
# release-process bugs that pipeline-level checks cannot see.

latest_obs <- function(data, value_col) {
  non_na <- data[!is.na(data[[value_col]]), ]
  ordered <- non_na[order(non_na$year, non_na$month), ]
  tail(ordered, 1)
}

check_against_fred <- function(data, value_col, fred_series, tol = 1e-3) {
  skip_on_cran()
  skip_if_offline()
  skip_if(
    Sys.getenv("FRED_API_KEY") == "",
    "FRED_API_KEY not set"
  )
  skip_if_not_installed("epidatatools")

  latest <- latest_obs(data, value_col)
  fred_date <- as.Date(sprintf("%d-%02d-01", latest$year, latest$month))

  fred <- epidatatools::get_fred(
    fred_series,
    start = fred_date,
    end = fred_date
  )

  expect_equal(nrow(fred), 1L)
  expect_equal(latest[[value_col]], fred$value, tolerance = tol)
}

test_that("cpi_u_monthly_nsa latest value matches FRED (CPIAUCNS)", {
  check_against_fred(cpi_u_monthly_nsa, "cpi_u", "CPIAUCNS")
})

test_that("c_cpi_u_monthly_nsa latest value matches FRED (SUUR0000SA0)", {
  check_against_fred(c_cpi_u_monthly_nsa, "c_cpi_u", "SUUR0000SA0")
})

test_that("pce_monthly_sa latest value matches FRED (PCEPI)", {
  check_against_fred(pce_monthly_sa, "pce", "PCEPI")
})
