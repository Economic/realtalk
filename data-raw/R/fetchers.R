fetch_bls_series <- function(
  series_id,
  start_year,
  end_year = year(Sys.Date())
) {
  get_bls(series_id, start = start_year, end = end_year) |>
    select(year, month, value) |>
    assert_rows(col_concat, is_uniq, year, month)
}

fetch_cpi_u_nsa <- function() {
  fetch_bls_series("CUUR0000SA0", 1937)
}

fetch_cpi_u_sa <- function() {
  fetch_bls_series("CUSR0000SA0", 1947)
}

fetch_c_cpi_u <- function() {
  fetch_bls_series("SUUR0000SA0", 1999)
}

fetch_pce_monthly_sa <- function() {
  get_bea_nipa("T20804", frequency = "month", years = "ALL") |>
    filter(line_number == 1) |>
    select(year, month, pce = value)
}

fetch_pce_quarterly_sa <- function() {
  get_bea_nipa("T20304", frequency = "quarter", years = "ALL") |>
    filter(line_number == 1) |>
    select(year, quarter, pce = value)
}

fetch_pce_annual <- function() {
  get_bea_nipa("T20304", frequency = "year", years = "ALL") |>
    filter(line_number == 1) |>
    select(year, pce = value)
}
