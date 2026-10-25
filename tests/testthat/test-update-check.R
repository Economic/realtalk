test_that("the check runs only in interactive sessions, when enabled, outside renv", {
  expect_true(should_check_for_update(TRUE, TRUE, ""))
  expect_false(should_check_for_update(FALSE, TRUE, ""))
  expect_false(should_check_for_update(TRUE, FALSE, ""))
  expect_false(should_check_for_update(TRUE, TRUE, "/home/someone/project"))
})

test_that("an unset option leaves the check on", {
  expect_true(should_check_for_update(TRUE, NULL, ""))
})

test_that("latest_cpi_month() skips missing values at the end", {
  data <- data.frame(year = 2026, month = 7:10, cpi_u = c(1, 2, 3, NA))
  expect_equal(latest_cpi_month(data), c(year = 2026, month = 9))
})

test_that("latest_cpi_month() works on the package's own data", {
  latest <- latest_cpi_month(cpi_u_monthly_nsa)
  expect_named(latest, c("year", "month"))
  expect_false(anyNA(latest))
})

test_that("months_behind() counts whole months, across a year boundary", {
  september <- c(year = 2026, month = 9)
  expect_equal(months_behind(september, as.Date("2026-10-24")), 1)
  expect_equal(months_behind(september, as.Date("2026-11-13")), 2)
  expect_equal(months_behind(september, as.Date("2027-01-02")), 4)
})

test_that("the message names the data's last month and the newer version", {
  message <- update_message(
    latest = c(year = 2026, month = 9),
    installed = "2026.10.14",
    available = "2026.11.13"
  )
  expect_match(message, "runs through September 2026")
  expect_match(message, "version 2026.11.13 is available")
  expect_match(message, "realtalk.update_check = FALSE", fixed = TRUE)
})

test_that("there is no message when nothing newer is available", {
  september <- c(year = 2026, month = 9)
  expect_null(update_message(september, "2026.10.14", "2026.10.14"))
  # a development version newer than r-universe's
  expect_null(update_message(september, "2026.11.20", "2026.11.13"))
})

test_that("there is no message when r-universe can't be reached", {
  expect_null(update_message(
    c(year = 2026, month = 9),
    "2026.10.14",
    NA_character_
  ))
})

test_that("versions compare as versions, including zero-padded ones", {
  message <- update_message(
    c(year = 2026, month = 1),
    "2026.02.13",
    "2026.3.11"
  )
  expect_match(message, "version 2026.3.11 is available")
})
