fetch_c_cpi_u <- function(download_date) {
  # C-CPI-U-NSA from BLS, available 1999m12+
  BLS_API_KEY <- Sys.getenv("BLS_API_KEY")

  c_cpi_u_file_path <- "data-raw/raw/c_cpi_u_nsa.csv"

  blsR::get_series_table(
    "SUUR0000SA0",
    BLS_API_KEY,
    start_year = 1999,
    end_year = 2024
  ) %>%
    suppressMessages() %>%
    select(year, period, value) %>%
    write_csv(c_cpi_u_file_path)

  c_cpi_u_file_path
}

fetch_cpi_u_sa <- function(download_date) {
  # CPI-U-SA from BLS, available 1947+
  BLS_API_KEY <- Sys.getenv("BLS_API_KEY")

  cpi_u_sa_file_path <- "data-raw/raw/cpi_u_sa.csv"

  blsR::get_series_table(
    "CUSR0000SA0",
    BLS_API_KEY,
    start_year = 1947,
    end_year = 2024
  ) %>%
    suppressMessages() %>%
    select(year, period, value) %>%
    write_csv(cpi_u_sa_file_path)

  cpi_u_sa_file_path
}

fetch_cpi_u_nsa <- function(download_date) {
  # CPI-U-NSA from BLS, available 1937+
  BLS_API_KEY <- Sys.getenv("BLS_API_KEY")

  cpi_u_nsa_file_path <- "data-raw/raw/cpi_u_nsa.csv"

  blsR::get_series_table(
    "CUUR0000SA0",
    BLS_API_KEY,
    start_year = 1937,
    end_year = 2024
  ) %>%
    suppressMessages() %>%
    select(year, period, value) %>%
    write_csv(cpi_u_nsa_file_path)

  cpi_u_nsa_file_path
}

fetch_pce_monthly_sa <- function(download_date) {
  # PCE, monthly available 1959+
  BEA_API_KEY <- Sys.getenv("BEA_API_KEY")

  pce_monthly_sa_file_path <- "data-raw/raw/pce_monthly_sa.csv"

  beaSpecs <- list(
    'UserID' = BEA_API_KEY ,
    'Method' = 'GetData',
    'datasetname' = 'NIPA',
    'TableName' = 'T20804',
    'Frequency' = 'M',
    'Year' = 'X'
  )

  bea.R::beaGet(beaSpecs, asWide = FALSE) %>%
    as_tibble() %>%
    janitor::clean_names() %>%
    filter(line_number == 1) %>%
    select(time_period, data_value) %>%
    write_csv(pce_monthly_sa_file_path)

  pce_monthly_sa_file_path
}

fetch_pce_annual <- function(download_date) {
  # PCE, annual available 1929+
  BEA_API_KEY <- Sys.getenv("BEA_API_KEY")

  pce_annual_file_path <- "data-raw/raw/pce_annual.csv"

  beaSpecs <- list(
    'UserID' = BEA_API_KEY ,
    'Method' = 'GetData',
    'datasetname' = 'NIPA',
    'TableName' = 'T20304',
    'Frequency' = 'A',
    'Year' = 'X'
  )

  bea.R::beaGet(beaSpecs, asWide = FALSE) %>%
    as_tibble() %>%
    janitor::clean_names() %>%
    filter(line_number == 1) %>%
    select(time_period, data_value) %>%
    write_csv(pce_annual_file_path)

  pce_annual_file_path

}

fetch_pce_quarterly_sa <- function(download_date) {
  # PCE, quarterly available 1947+
  BEA_API_KEY <- Sys.getenv("BEA_API_KEY")

  pce_quarterly_sa_file_path <- "data-raw/raw/pce_quarterly_sa.csv"

  beaSpecs <- list(
    'UserID' = BEA_API_KEY ,
    'Method' = 'GetData',
    'datasetname' = 'NIPA',
    'TableName' = 'T20304',
    'Frequency' = 'Q',
    'Year' = 'X'
  )

  bea.R::beaGet(beaSpecs, asWide = FALSE) %>%
    as_tibble() %>%
    janitor::clean_names() %>%
    filter(line_number == 1) %>%
    select(time_period, data_value) %>%
    write_csv(pce_quarterly_sa_file_path)

  pce_quarterly_sa_file_path
}





