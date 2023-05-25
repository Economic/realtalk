read_cpi_u_rs <- function(csv) {
  read_csv(csv) %>%
    rename_all(tolower) %>%
    select(-avg) %>%
    pivot_longer(-year, names_to = "month", values_to = "cpi_u_rs") %>%
    mutate(month = month(ym(paste(year, month)))) %>%
    filter(!is.na(cpi_u_rs)) %>%
    arrange(year, month)
}


create_cpi_u_rs <- function(raw_csv) {
  ### MONTHLY
  monthly_nsa_csv <- "data-raw/processed/cpi_u_rs_monthly_nsa.csv"
  monthly_nsa_rda <- "data/cpi_u_rs_monthly_nsa.rda"

  cpi_u_rs_monthly_nsa <- read_cpi_u_rs(raw_csv)

  cpi_u_rs_monthly_nsa %>%
    write_csv(monthly_nsa_csv)

  usethis::use_data(cpi_u_rs_monthly_nsa, overwrite = TRUE)

  output_monthly <- c(monthly_nsa_csv, monthly_nsa_rda)


  ### ANNUAL
  annual_csv <- "data-raw/processed/cpi_u_rs_annual.csv"
  annual_rda <- "data/cpi_u_rs_annual.rda"

  cpi_u_rs_annual <- cpi_u_rs_monthly_nsa %>%
    # first full year of data = 1978
    filter(year >= 1978) %>%
    summarize(cpi_u_rs = mean(cpi_u_rs), .by = year) %>%
    mutate(cpi_u_rs = round(cpi_u_rs, digits = 1)) %>%
    arrange(year)

  cpi_u_rs_annual %>%
    write_csv(annual_csv)

  usethis::use_data(cpi_u_rs_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_annual)
  output
}
