# Run with data-raw/tests/run.R.

snapshots <- list(
  cpi_u_nsa = tibble(year = 2026, month = c(9, 10), value = c(336.9, 337.5)),
  pce_monthly_sa = tibble(year = 2026, month = c(8, 9), pce = c(131.6, 131.9))
)

test_that("the notice names the latest CPI and PCE months in its title", {
  notice <- new_data_notice("cpi_u_nsa.csv", snapshots)
  expect_equal(
    notice$title,
    "New data: CPI through October 2026, PCE through September 2026"
  )
})

test_that("the notice lists the changed snapshots and the next step", {
  notice <- new_data_notice(c("cpi_u_nsa.csv", "cpi_u_sa.csv"), snapshots)
  expect_contains(notice$body, c("- `cpi_u_nsa.csv`", "- `cpi_u_sa.csv`"))
  expect_contains(
    notice$body,
    "Next: run **Draft update** from the Actions tab."
  )
})

test_that("the notice adds stale-input warnings only when there are some", {
  without <- new_data_notice("cpi_u_nsa.csv", snapshots)
  with <- new_data_notice(
    "cpi_u_nsa.csv",
    snapshots,
    stale = "CPI-U-RS has no annual value for 2026."
  )
  expect_false(any(str_detect(without$body, "Hand-maintained")))
  expect_contains(with$body, "- CPI-U-RS has no annual value for 2026.")
})
