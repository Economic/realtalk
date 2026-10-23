# Run with data-raw/tests/run.R. FRED is replaced by a stand-in `fetch`.

three_months <- function(column) {
  tibble(year = 2026, month = 7:9, !!column := c(100.111, 100.222, 100.333))
}

datasets <- list(
  cpi_u_monthly_nsa = three_months("cpi_u"),
  cpi_u_monthly_sa = three_months("cpi_u"),
  c_cpi_u_monthly_nsa = three_months("c_cpi_u"),
  pce_monthly_sa = three_months("pce")
)

# A stand-in for get_fred() that returns the same values, minus any months
# listed in `drop`, with `change` added to `changed_series`
fake_fred <- function(drop = character(), changed_series = NULL, change = 0) {
  function(series, start, fred_api_key) {
    expand_grid(series_id = series, month = 7:9) |>
      mutate(
        year = 2026,
        value = c(100.111, 100.222, 100.333)[month - 6],
        value = if_else(series_id %in% changed_series, value + change, value)
      ) |>
      filter(!paste0(year, "m", month) %in% drop)
  }
}

test_that("matching values are verified", {
  result <- verify_against_fred(datasets, api_key = "key", fetch = fake_fred())
  expect_equal(result$status, rep("verified", 4))
  expect_equal(result$months_checked, rep(3L, 4))
})

test_that("months FRED doesn't have yet are listed, not failed", {
  result <- verify_against_fred(
    datasets,
    api_key = "key",
    fetch = fake_fred(drop = "2026m9")
  )
  expect_equal(result$not_on_fred, rep("2026m9", 4))
  expect_equal(result$months_checked, rep(2L, 4))
})

test_that("a value that differs from FRED stops the pipeline", {
  expect_error(
    verify_against_fred(
      datasets,
      api_key = "key",
      fetch = fake_fred(changed_series = "PCEPI", change = 0.01)
    ),
    "pce_monthly_sa 2026m7"
  )
})

test_that("a difference beyond three decimals is not a mismatch", {
  result <- verify_against_fred(
    datasets,
    api_key = "key",
    fetch = fake_fred(changed_series = "PCEPI", change = 0.0001)
  )
  expect_equal(result$status, rep("verified", 4))
})

test_that("without a key, it warns and records 'not run'", {
  expect_warning(
    result <- verify_against_fred(datasets, api_key = "", require_key = FALSE),
    "did not run"
  )
  expect_equal(result$status, rep("not run", 4))
})

test_that("without a key, it fails when a key is required", {
  expect_error(
    verify_against_fred(datasets, api_key = "", require_key = TRUE),
    "REALTALK_REQUIRE_FRED"
  )
})
