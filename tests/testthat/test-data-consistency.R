# Consistency checks on the package's own datasets. They need no network, so
# they run in R CMD check, the PR check, and r-universe's build. The checking
# functions are in helper-data-checks.R.

time_series <- list(
  cpi_u_monthly_nsa = cpi_u_monthly_nsa,
  cpi_u_monthly_sa = cpi_u_monthly_sa,
  cpi_u_quarterly_nsa = cpi_u_quarterly_nsa,
  cpi_u_quarterly_sa = cpi_u_quarterly_sa,
  cpi_u_annual = cpi_u_annual,
  c_cpi_u_monthly_nsa = c_cpi_u_monthly_nsa,
  c_cpi_u_quarterly_nsa = c_cpi_u_quarterly_nsa,
  c_cpi_u_annual = c_cpi_u_annual,
  c_cpi_u_extended_monthly_nsa = c_cpi_u_extended_monthly_nsa,
  c_cpi_u_extended_monthly_sa = c_cpi_u_extended_monthly_sa,
  c_cpi_u_extended_quarterly_nsa = c_cpi_u_extended_quarterly_nsa,
  c_cpi_u_extended_quarterly_sa = c_cpi_u_extended_quarterly_sa,
  c_cpi_u_extended_annual = c_cpi_u_extended_annual,
  cpi_u_rs_monthly_nsa = cpi_u_rs_monthly_nsa,
  cpi_u_rs_annual = cpi_u_rs_annual,
  cpi_u_x1_monthly_nsa = cpi_u_x1_monthly_nsa,
  cpi_u_x1_annual = cpi_u_x1_annual,
  pce_monthly_sa = pce_monthly_sa,
  pce_quarterly_sa = pce_quarterly_sa,
  pce_annual = pce_annual,
  us_minimum_wage_monthly = us_minimum_wage_monthly,
  us_minimum_wage_annual = us_minimum_wage_annual
)

# Quarterly and annual price indexes built by averaging a monthly dataset.
# PCE comes from BEA at each frequency, and the minimum wage's annual value is
# the year's highest rate, so neither is listed.
aggregations <- list(
  list("cpi_u_quarterly_nsa", "cpi_u_monthly_nsa"),
  list("cpi_u_quarterly_sa", "cpi_u_monthly_sa"),
  list("cpi_u_annual", "cpi_u_monthly_nsa"),
  list("c_cpi_u_quarterly_nsa", "c_cpi_u_monthly_nsa"),
  list("c_cpi_u_annual", "c_cpi_u_monthly_nsa"),
  list("c_cpi_u_extended_quarterly_nsa", "c_cpi_u_extended_monthly_nsa"),
  list("c_cpi_u_extended_quarterly_sa", "c_cpi_u_extended_monthly_sa"),
  list("cpi_u_rs_annual", "cpi_u_rs_monthly_nsa"),
  list("cpi_u_x1_annual", "cpi_u_x1_monthly_nsa")
)

test_that("no dataset has gaps apart from the known missing months", {
  for (name in names(time_series)) {
    expect_equal(find_gaps(time_series[[name]]), character(), label = name)
  }
})

test_that("no dataset repeats a period", {
  for (name in names(time_series)) {
    expect_equal(
      find_duplicates(time_series[[name]]),
      character(),
      label = name
    )
  }
})

test_that("quarterly and annual price indexes cover only complete periods", {
  for (pair in aggregations) {
    expect_equal(
      find_incomplete_periods(
        time_series[[pair[[1]]]],
        time_series[[pair[[2]]]]
      ),
      character(),
      label = pair[[1]]
    )
  }
})

test_that("extended C-CPI-U matches C-CPI-U from 2000, monthly and annual", {
  expect_equal(
    find_disagreements(
      c_cpi_u_extended_monthly_nsa,
      c_cpi_u_monthly_nsa,
      tolerance = 0.05,
      skip = missing_month_index(known_missing_months)
    ),
    character()
  )
  expect_equal(
    find_disagreements(
      c_cpi_u_extended_annual,
      c_cpi_u_annual,
      tolerance = 0.05
    ),
    character()
  )
})

test_that("extended C-CPI-U matches C-CPI-U from 2000 within a rounding unit, quarterly", {
  # The extended quarterly values average monthly values already rounded to one
  # decimal, so they can differ by 0.1. Quarters with a known missing month are
  # skipped: the extended series interpolates that month.
  expect_equal(
    find_disagreements(
      c_cpi_u_extended_quarterly_nsa,
      c_cpi_u_quarterly_nsa,
      tolerance = 0.1,
      skip = quarters_with_missing_months(known_missing_months)
    ),
    character()
  )
})

# The checks themselves, on deliberately broken data

monthly <- data.frame(
  year = 2025L,
  month = 8:12,
  value = c(1, 2, NA, 4, 5)
)
october_missing <- data.frame(year = 2025L, month = 10L)

test_that("find_gaps() accepts a known missing month as NA or absent", {
  expect_equal(find_gaps(monthly, october_missing), character())
  expect_equal(find_gaps(monthly[-3, ], october_missing), character())
})

test_that("find_gaps() reports a missing or NA month that isn't known", {
  no_missing <- october_missing[0, ]
  expect_equal(find_gaps(monthly, no_missing), "2025m10")
  expect_equal(find_gaps(monthly[-2, ], october_missing), "2025m9")
})

test_that("find_duplicates() reports a repeated period", {
  expect_equal(find_duplicates(monthly), character())
  expect_equal(find_duplicates(monthly[c(1, 1, 2), ]), "2025m8")
})

test_that("find_incomplete_periods() counts a known missing month as present", {
  quarter <- data.frame(year = 2025L, quarter = 4L, value = 1)
  expect_equal(
    find_incomplete_periods(quarter, monthly, october_missing),
    character()
  )
  expect_equal(
    find_incomplete_periods(quarter, monthly[-4, ], october_missing),
    "2025q4"
  )
})

test_that("find_disagreements() reports differences above the tolerance only", {
  a <- data.frame(year = 2000L, month = 1:3, value = c(100, 100.05, 100.2))
  b <- data.frame(year = 2000L, month = 1:3, value = c(100, 100, 100))
  expect_equal(find_disagreements(a, b, tolerance = 0.05), "2000m3")
  expect_equal(
    find_disagreements(a, b, tolerance = 0.05, skip = 2000L * 12L + 2L),
    character()
  )
  expect_equal(
    find_disagreements(a, b, tolerance = 0.05, from_year = 2001),
    character()
  )
})
