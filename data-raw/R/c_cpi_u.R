# # C-CPI-U-NSA from BLS, available 1999m12+
# BLS_API_KEY <- Sys.getenv("BLS_API_KEY")
#
# blsR::get_series_table(
#   "SUUR0000SA0",
#   BLS_API_KEY,
#   start_year = 1999,
#   end_year = 2023
# ) %>%
#   select(year, period, value) %>%
#   write_csv("data-raw/raw/c_cpi_u_nsa.csv")

read_c_cpi_u <- function(csv) {
  read_csv(csv) %>%
    mutate(month = as.numeric(str_sub(period, 2, 3))) %>%
    filter(month %in% 1:12) %>%
    select(year, month, c_cpi_u = value) %>%
    arrange(year, month)
}

create_c_cpi_u <- function(raw_nsa_csv) {
  ### MONTHLY
  monthly_nsa_csv <- "data-raw/processed/c_cpi_u_monthly_nsa.csv"
  monthly_nsa_rda <- "data/c_cpi_u_monthly_nsa.rda"

  c_cpi_u_monthly_nsa <- read_c_cpi_u(raw_nsa_csv)

  c_cpi_u_monthly_nsa %>%
    write_csv(monthly_nsa_csv)

  usethis::use_data(c_cpi_u_monthly_nsa, overwrite = TRUE)

  output_monthly <- c(
    monthly_nsa_csv,
    monthly_nsa_rda
  )


  ### ANNUAL
  annual_csv <- "data-raw/processed/c_cpi_u_annual.csv"
  annual_rda <- "data/c_cpi_u_annual.rda"

  c_cpi_u_annual <- c_cpi_u_monthly_nsa %>%
    # first full year of data = 2000
    filter(year >= 2000) %>%
    summarize(c_cpi_u = mean(c_cpi_u), .by = year) %>%
    mutate(c_cpi_u = round(c_cpi_u, digits = 1)) %>%
    arrange(year)

  c_cpi_u_annual %>%
    write_csv(annual_csv)

  usethis::use_data(c_cpi_u_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_annual)
  output
}
