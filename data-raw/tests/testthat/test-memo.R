# Run with data-raw/tests/run.R, which loads the pipeline's packages and
# functions first.

monthly_series <- function(column, from, to, values = NULL) {
  months <- seq(ym(from), ym(to), by = "month")
  if (is.null(values)) {
    values <- seq_along(months) + 100
  }
  tibble(year = year(months), month = month(months), !!column := values)
}

# A C-CPI-U baseline through June 2026, as in v2026.7.14
c_cpi_u_baseline <- monthly_series("c_cpi_u", "2024-01", "2026-06")
cpi_u_baseline <- monthly_series("cpi_u", "2024-01", "2026-06")

revise <- function(data, column, year, month, change) {
  data |>
    mutate(
      "{column}" := if_else(
        .data$year == !!year & .data$month == !!month,
        .data[[column]] + change,
        .data[[column]]
      )
    )
}

unexpected <- function(cpi_u = cpi_u_baseline, c_cpi_u = c_cpi_u_baseline) {
  find_unexpected_revisions(
    baseline = list(
      cpi_u_monthly_nsa = cpi_u_baseline,
      c_cpi_u_monthly_nsa = c_cpi_u_baseline
    ),
    current = list(cpi_u_monthly_nsa = cpi_u, c_cpi_u_monthly_nsa = c_cpi_u)
  )
}

test_that("an update that only adds months has no unexpected revisions", {
  next_month <- bind_rows(
    cpi_u_baseline,
    tibble(year = 2026, month = 7, cpi_u = 200)
  )
  expect_equal(nrow(unexpected(cpi_u = next_month)), 0)
})

test_that("a revised historical CPI-U NSA value is unexpected", {
  result <- unexpected(cpi_u = revise(cpi_u_baseline, "cpi_u", 2025, 3, 0.1))
  expect_equal(result$period, "2025m3")
  expect_equal(result$dataset, "cpi_u_monthly_nsa")
})

test_that("a removed CPI-U NSA month is unexpected", {
  result <- unexpected(cpi_u = cpi_u_baseline[-5, ])
  expect_equal(result$period, "2024m5")
})

test_that("C-CPI-U revisions to interim months are expected", {
  # July 2025 is 11 months older than the baseline's June 2026: interim
  result <- unexpected(
    c_cpi_u = revise(c_cpi_u_baseline, "c_cpi_u", 2025, 7, 0.1)
  )
  expect_equal(nrow(result), 0)
})

test_that("a C-CPI-U revision 12 or more months back is unexpected", {
  # June 2025 is exactly 12 months older than the baseline's June 2026: final
  result <- unexpected(
    c_cpi_u = revise(c_cpi_u_baseline, "c_cpi_u", 2025, 6, 0.1)
  )
  expect_equal(result$period, "2025m6")
  expect_equal(result$dataset, "c_cpi_u_monthly_nsa")
})

test_that("a month that was NA in the baseline isn't reported", {
  with_gap <- c_cpi_u_baseline |>
    mutate(c_cpi_u = if_else(year == 2025 & month == 1, NA, c_cpi_u))
  filled <- c_cpi_u_baseline
  result <- find_unexpected_revisions(
    baseline = list(
      cpi_u_monthly_nsa = cpi_u_baseline,
      c_cpi_u_monthly_nsa = with_gap
    ),
    current = list(
      cpi_u_monthly_nsa = cpi_u_baseline,
      c_cpi_u_monthly_nsa = filled
    )
  )
  expect_equal(nrow(result), 0)
})

test_that("summarize_changes() counts added, removed, and revised periods", {
  old <- monthly_series("pce", "2026-01", "2026-04")
  new <- monthly_series("pce", "2026-02", "2026-05") |>
    revise("pce", 2026, 3, 0.5)
  result <- summarize_changes("pce_monthly_sa", old, new)
  expect_equal(result$added, 1)
  expect_equal(result$removed, 1)
  expect_equal(result$revised, 3)
  expect_equal(result$revised_range, "2026m2 to 2026m4")
})

test_that("find_baseline_ref() uses REALTALK_BASELINE when it's set", {
  expect_equal(find_baseline_ref("v2026.9.11"), "v2026.9.11")
})

test_that("find_stale_inputs() warns about CPI-U-RS only after May", {
  current <- list(
    cpi_u_rs_annual = tibble(year = 2024, cpi_u_rs = 1),
    us_minimum_wage_monthly = tibble(
      year = 2026,
      month = 12,
      minimum_wage = 7.25
    )
  )
  expect_length(find_stale_inputs(current, as.Date("2026-05-15")), 0)
  expect_match(find_stale_inputs(current, as.Date("2026-06-15")), "CPI-U-RS")
})

test_that("find_stale_inputs() warns when the minimum wage ends before this year", {
  current <- list(
    cpi_u_rs_annual = tibble(year = 2026, cpi_u_rs = 1),
    us_minimum_wage_monthly = tibble(
      year = 2026,
      month = 12,
      minimum_wage = 7.25
    )
  )
  expect_length(find_stale_inputs(current, as.Date("2026-11-01")), 0)
  expect_match(find_stale_inputs(current, as.Date("2027-01-15")), "final_year")
})
