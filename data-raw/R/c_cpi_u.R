read_c_cpi_u <- function(csv) {
  read_csv(csv, show_col_types = FALSE) %>%
    mutate(month = as.numeric(str_sub(period, 2, 3))) %>%
    filter(month %in% 1:12) %>%
    mutate(value = as.numeric(value)) |>
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

  ### QUARTERLY
  quarterly_nsa_csv <- "data-raw/processed/c_cpi_u_quarterly_nsa.csv"
  quarterly_nsa_rda <- "data/c_cpi_u_quarterly_nsa.rda"

  c_cpi_u_quarterly_nsa <- c_cpi_u_monthly_nsa |>
    mutate(quarter = quarter(month)) |>
    mutate(month_count = sum(!is.na(month)), .by = c(year, quarter)) %>%
    filter(month_count == 3) %>%
    summarize(
      c_cpi_u = mean(c_cpi_u),
      .by = c(year, quarter)
    ) %>%
    mutate(c_cpi_u = round(c_cpi_u, digits = 1)) %>%
    arrange(year, quarter)

  c_cpi_u_quarterly_nsa %>%
    write_csv(quarterly_nsa_csv)

  usethis::use_data(c_cpi_u_quarterly_nsa, overwrite = TRUE)

  output_quarterly <- c(
    quarterly_nsa_csv,
    quarterly_nsa_rda
  )

  ### ANNUAL
  annual_csv <- "data-raw/processed/c_cpi_u_annual.csv"
  annual_rda <- "data/c_cpi_u_annual.rda"

  c_cpi_u_annual <- c_cpi_u_monthly_nsa %>%
    # only annualize data where 12 months of values exist
    mutate(month_count = sum(!is.na(month)), .by = year) %>%
    filter(month_count == 12) %>%
    summarize(c_cpi_u = mean(c_cpi_u), .by = year) %>%
    mutate(c_cpi_u = round(c_cpi_u, digits = 1)) %>%
    arrange(year)

  c_cpi_u_annual %>%
    write_csv(annual_csv)

  usethis::use_data(c_cpi_u_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_quarterly, output_annual)
  output
}
