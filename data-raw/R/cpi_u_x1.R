read_cpi_u_x1 <- function(csv) {
  read_csv(csv) %>%
    rename_all(tolower) %>%
    select(-aavg) %>%
    pivot_longer(-year, names_to = "month", values_to = "cpi_u_x1") %>%
    mutate(month = month(ym(paste(year, month)))) %>%
    filter(!is.na(cpi_u_x1)) %>%
    arrange(year, month)
}

create_cpi_u_x1 <- function(raw_csv) {
  ### MONTHLY
  monthly_nsa_csv <- "data-raw/processed/cpi_u_x1_monthly_nsa.csv"
  monthly_nsa_rda <- "data/cpi_u_x1_monthly_nsa.rda"

  cpi_u_x1_monthly_nsa <- read_cpi_u_x1(raw_csv)

  cpi_u_x1_monthly_nsa %>%
    write_csv(monthly_nsa_csv)

  usethis::use_data(cpi_u_x1_monthly_nsa, overwrite = TRUE)

  output_monthly <- c(monthly_nsa_csv, monthly_nsa_rda)


  ### ANNUAL
  annual_csv <- "data-raw/processed/cpi_u_x1_annual.csv"
  annual_rda <- "data/cpi_u_x1_annual.rda"

  cpi_u_x1_annual <- cpi_u_x1_monthly_nsa %>%
    summarize(cpi_u_x1 = mean(cpi_u_x1), .by = year) %>%
    mutate(cpi_u_x1 = round(cpi_u_x1, digits = 1)) %>%
    arrange(year)

  cpi_u_x1_annual %>%
    write_csv(annual_csv)

  usethis::use_data(cpi_u_x1_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_annual)
  output
}
