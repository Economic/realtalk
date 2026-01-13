read_cpi_u <- function(csv) {
  read_csv(csv, show_col_types = FALSE) %>%
    mutate(month = as.numeric(str_sub(period, 2, 3))) %>%
    filter(month %in% 1:12) %>%
    mutate(value = as.numeric(value)) |>
    select(year, month, cpi_u = value) %>%
    arrange(year, month)
}

create_cpi_u <- function(raw_nsa_csv, raw_sa_csv) {
  ### MONTHLY
  monthly_nsa_csv <- "data-raw/processed/cpi_u_monthly_nsa.csv"
  monthly_nsa_rda <- "data/cpi_u_monthly_nsa.rda"
  monthly_sa_csv <- "data-raw/processed/cpi_u_monthly_sa.csv"
  monthly_sa_rda <- "data/cpi_u_monthly_sa.rda"

  cpi_u_monthly_nsa <- read_cpi_u(raw_nsa_csv)
  cpi_u_monthly_sa <- read_cpi_u(raw_sa_csv)

  cpi_u_monthly_nsa %>%
    write_csv(monthly_nsa_csv)
  cpi_u_monthly_sa %>%
    write_csv(monthly_sa_csv)

  usethis::use_data(cpi_u_monthly_nsa, overwrite = TRUE)
  usethis::use_data(cpi_u_monthly_sa, overwrite = TRUE)

  output_monthly <- c(
    monthly_nsa_csv,
    monthly_nsa_rda,
    monthly_sa_csv,
    monthly_sa_rda
  )

  ### QUARTERLY
  quarterly_nsa_csv <- "data-raw/processed/cpi_u_quarterly_nsa.csv"
  quarterly_nsa_rda <- "data/cpi_u_quarterly_nsa.rda"
  quarterly_sa_csv <- "data-raw/processed/cpi_u_quarterly_sa.csv"
  quarterly_sa_rda <- "data/cpi_u_quarterly_sa.rda"

  cpi_u_quarterly_nsa <- cpi_u_monthly_nsa |>
    mutate(quarter = quarter(month)) |>
    mutate(month_count = sum(!is.na(month)), .by = c(year, quarter)) %>%
    filter(month_count == 3 | (year == 2025 & quarter == 4 & month_count == 2)) %>%
    summarize(
      cpi_u = mean(cpi_u, na.rm = TRUE),
      .by = c(year, quarter)
    ) %>%
    mutate(cpi_u = round(cpi_u, digits = 1)) %>%
    arrange(year, quarter)

  cpi_u_quarterly_sa <- cpi_u_monthly_sa |>
    mutate(quarter = quarter(month)) |>
    mutate(month_count = sum(!is.na(month)), .by = c(year, quarter)) %>%
    filter(month_count == 3 | (year == 2025 & quarter == 4 & month_count == 2)) %>%
    summarize(
      cpi_u = mean(cpi_u, na.rm = TRUE),
      .by = c(year, quarter)
    ) %>%
    mutate(cpi_u = round(cpi_u, digits = 1)) %>%
    arrange(year, quarter)

  cpi_u_quarterly_nsa %>%
    write_csv(quarterly_nsa_csv)
  cpi_u_quarterly_sa %>%
    write_csv(quarterly_sa_csv)

  usethis::use_data(cpi_u_quarterly_nsa, overwrite = TRUE)
  usethis::use_data(cpi_u_quarterly_sa, overwrite = TRUE)

  output_quarterly <- c(
    quarterly_nsa_csv,
    quarterly_nsa_rda,
    quarterly_sa_csv,
    quarterly_sa_rda
  )

  ### ANNUAL
  annual_csv <- "data-raw/processed/cpi_u_annual.csv"
  annual_rda <- "data/cpi_u_annual.rda"

  cpi_u_annual <- cpi_u_monthly_nsa %>%
    # only annualize data where 12 months of values exist
    mutate(month_count = sum(!is.na(month)), .by = year) %>%
    filter(month_count == 12 | (year == 2025 & month_count == 11)) %>%
    summarize(cpi_u = mean(cpi_u, na.rm = TRUE), .by = year) %>%
    mutate(cpi_u = round(cpi_u, digits = 1)) %>%
    arrange(year)

  cpi_u_annual %>%
    write_csv(annual_csv)

  usethis::use_data(cpi_u_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_quarterly, output_annual)
  output
}
