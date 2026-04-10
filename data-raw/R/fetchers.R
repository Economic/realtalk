fetch_bls_series <- function(series_id, file_path, start_year, end_year) {
  get_bls(series_id, start = start_year, end = end_year) |>
    select(year, month, value) |>
    write_csv(file_path)
  file_path
}

fetch_cpi_u_nsa <- function() {
  fetch_bls_series("CUUR0000SA0", "data-raw/raw/cpi_u_nsa.csv", 1937, 2026)
}

fetch_cpi_u_sa <- function() {
  fetch_bls_series("CUSR0000SA0", "data-raw/raw/cpi_u_sa.csv", 1947, 2026)
}

fetch_c_cpi_u <- function() {
  fetch_bls_series("SUUR0000SA0", "data-raw/raw/c_cpi_u_nsa.csv", 1999, 2026)
}

fetch_pce_monthly_sa <- function() {
  file_path <- "data-raw/raw/pce_monthly_sa.csv"
  get_bea_nipa("T20804", frequency = "month", years = "ALL") |>
    filter(line_number == 1) |>
    select(year, month, pce = value) |>
    write_csv(file_path)
  file_path
}

fetch_pce_quarterly_sa <- function() {
  file_path <- "data-raw/raw/pce_quarterly_sa.csv"
  get_bea_nipa("T20304", frequency = "quarter", years = "ALL") |>
    filter(line_number == 1) |>
    select(year, quarter, pce = value) |>
    write_csv(file_path)
  file_path
}

fetch_pce_annual <- function() {
  file_path <- "data-raw/raw/pce_annual.csv"
  get_bea_nipa("T20304", frequency = "year", years = "ALL") |>
    filter(line_number == 1) |>
    select(year, pce = value) |>
    write_csv(file_path)
  file_path
}
