# Run with data-raw/tests/run.R.

test_that("next_version() uses the date when it's not released", {
  expect_equal(
    next_version(as.Date("2026-10-23"), c("v2026.10.14", "v2026.9.11")),
    "2026.10.23"
  )
})

test_that("next_version() adds a suffix for a second version the same day", {
  expect_equal(
    next_version(as.Date("2026-10-14"), "v2026.10.14"),
    "2026.10.14.1"
  )
  expect_equal(
    next_version(as.Date("2026-10-14"), c("v2026.10.14", "v2026.10.14.1")),
    "2026.10.14.2"
  )
})

test_that("next_version() compares with zero-padded older tags as versions", {
  expect_equal(
    next_version(as.Date("2026-02-13"), "v2026.02.13"),
    "2026.2.13.1"
  )
})

test_that("today_eastern() turns at midnight Eastern, in summer and winter", {
  expect_equal(
    today_eastern(as.POSIXct("2026-07-01 03:30", tz = "UTC")),
    as.Date("2026-06-30")
  )
  expect_equal(
    today_eastern(as.POSIXct("2026-07-01 04:30", tz = "UTC")),
    as.Date("2026-07-01")
  )
  expect_equal(
    today_eastern(as.POSIXct("2026-12-01 04:30", tz = "UTC")),
    as.Date("2026-11-30")
  )
  expect_equal(
    today_eastern(as.POSIXct("2026-12-01 05:30", tz = "UTC")),
    as.Date("2026-12-01")
  )
})

coverage <- function(cpi_to, pce_to, rs_to = 2025) {
  months <- function(to) seq(ym("2026-01"), ym(to), by = "month")
  list(
    cpi_u_monthly_nsa = tibble(
      year = year(months(cpi_to)),
      month = month(months(cpi_to)),
      cpi_u = 1
    ),
    pce_monthly_sa = tibble(
      year = year(months(pce_to)),
      month = month(months(pce_to)),
      pce = 1
    ),
    cpi_u_rs_annual = tibble(year = 2020:rs_to, cpi_u_rs = 1)
  )
}

test_that("news_entry() names each series whose coverage moved", {
  expect_equal(
    news_entry(coverage("2026-08", "2026-07"), coverage("2026-09", "2026-08")),
    c(
      "* update CPI-based data through September 2026",
      "* update PCE through August 2026"
    )
  )
  expect_equal(
    news_entry(
      coverage("2026-09", "2026-08", 2024),
      coverage("2026-09", "2026-08", 2025)
    ),
    "* update CPI-U-RS through 2025"
  )
})

test_that("news_entry() says 'revised data' when no coverage moved", {
  expect_equal(
    news_entry(coverage("2026-09", "2026-08"), coverage("2026-09", "2026-08")),
    "* update with revised data"
  )
})

news <- c(
  "## Version 2026.10.14",
  "* update CPI-based data through September 2026",
  "",
  "## Version 2026.9.11",
  "* update CPI-based data through August 2026"
)
released <- c("v2026.10.14", "v2026.9.11")
entry <- "* update PCE through September 2026"

test_that("add_news_entry() puts the new entry above a released one", {
  expect_equal(
    add_news_entry(news, "2026.10.30", entry, released),
    c("## Version 2026.10.30", entry, "", news)
  )
})

test_that("add_news_entry() folds an unreleased top entry into the new one", {
  unreleased <- c("## Version 2026.10.24", "* add an update check", "", news)
  expect_equal(
    add_news_entry(unreleased, "2026.10.30", entry, released),
    c("## Version 2026.10.30", entry, "* add an update check", "", news)
  )
})

test_that("add_news_entry() replaces an unreleased entry with the same version", {
  unreleased <- c("## Version 2026.10.30", "* add an update check", "", news)
  expect_equal(
    add_news_entry(unreleased, "2026.10.30", entry, released),
    c("## Version 2026.10.30", entry, "* add an update check", "", news)
  )
})

test_that("add_news_entry() treats zero-padded released tags as released", {
  padded <- c("## Version 2026.02.13", "* update CPI", "")
  expect_equal(
    add_news_entry(padded, "2026.3.11", entry, "v2026.02.13"),
    c("## Version 2026.3.11", entry, "", padded)
  )
})

test_that("add_news_entry() folds an unreleased entry that is the whole file", {
  only <- c("## Version 2026.10.24", "* add an update check")
  expect_equal(
    add_news_entry(only, "2026.10.30", entry, released),
    c("## Version 2026.10.30", entry, "* add an update check", "")
  )
})

test_that("add_news_entry() folds every unreleased entry above the last release", {
  two <- c(
    "## Version 2026.10.27",
    "* fix get_price_index()",
    "",
    "## Version 2026.10.24",
    "* add an update check",
    "",
    news
  )
  expect_equal(
    add_news_entry(two, "2026.10.30", entry, released),
    c(
      "## Version 2026.10.30",
      entry,
      "* fix get_price_index()",
      "* add an update check",
      "",
      news
    )
  )
})
