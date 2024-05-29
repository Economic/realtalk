create_pce <- function(raw_monthly_csv, raw_quarterly_csv, raw_annual_csv) {
  ### MONTHLY
  monthly_sa_csv <- "data-raw/processed/pce_monthly_sa.csv"
  monthly_sa_rda <- "data/pce_monthly_sa.rda"

  pce_monthly_sa <- read_csv(raw_monthly_csv, show_col_types = FALSE) %>%
    mutate(
      date = ym(time_period),
      year = year(date),
      month = month(date)
    ) %>%
    select(year, month, pce = data_value)

  pce_monthly_sa %>%
    write_csv(monthly_sa_csv)

  usethis::use_data(pce_monthly_sa, overwrite = TRUE)

  output_monthly <- c(monthly_sa_csv, monthly_sa_rda)


  ### QUARTERLY
  quarterly_sa_csv <- "data-raw/processed/pce_quarterly_sa.csv"
  quarterly_sa_rda <- "data/pce_quarterly_sa.rda"

  pce_quarterly_sa <- read_csv(raw_quarterly_csv, show_col_types = FALSE) %>%
    mutate(
      date = yq(time_period),
      year = year(date),
      quarter = quarter(date)
    ) %>%
    select(year, quarter, pce = data_value)

  pce_quarterly_sa %>%
    write_csv(quarterly_sa_csv)

  usethis::use_data(pce_quarterly_sa, overwrite = TRUE)

  output_quarterly <- c(quarterly_sa_csv, quarterly_sa_rda)


  ### ANNUAL
  annual_csv <- "data-raw/processed/pce_annual.csv"
  annual_rda <- "data/pce_annual.rda"

  pce_annual <- read_csv(raw_annual_csv, show_col_types = FALSE) %>%
    select(year = time_period, pce = data_value)

  pce_annual %>%
    write_csv(annual_csv)

  usethis::use_data(pce_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_quarterly, output_annual)
  output
}
