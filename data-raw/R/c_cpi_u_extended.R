create_c_cpi_u_extended <- function(cpi_u_data, cpi_u_x1_data, cpi_u_rs_data, c_cpi_u_data) {
  cpi_u_path <- tar_read(cpi_u_data) %>%
    str_subset("cpi_u_monthly_nsa.rda")
  cpi_u_x1_path <- tar_read(cpi_u_x1_data) %>%
    str_subset("cpi_u_x1_monthly_nsa.rda")
  cpi_u_rs_path <- tar_read(cpi_u_rs_data) %>%
    str_subset("cpi_u_rs_monthly_nsa.rda")
  c_cpi_u_path <- tar_read(c_cpi_u_data) %>%
    str_subset("c_cpi_u_monthly_nsa.rda")

  load(cpi_u_path)
  load(cpi_u_x1_path)
  load(cpi_u_rs_path)
  load(c_cpi_u_path)

  ### MONTHLY
  monthly_nsa_csv <- "data-raw/processed/c_cpi_u_extended_monthly_nsa.csv"
  monthly_nsa_rda <- "data/c_cpi_u_extended_monthly_nsa.rda"

  c_cpi_u_extended_monthly_nsa <- cpi_u_monthly_nsa %>%
    full_join(cpi_u_x1_monthly_nsa, by = c("year", "month")) %>%
    full_join(cpi_u_rs_monthly_nsa, by = c("year", "month")) %>%
    full_join(c_cpi_u_monthly_nsa, by = c("year", "month")) %>%
    mutate(date = ym(paste(year, month))) %>%
    chain_to_base(cpi_u_x1, cpi_u_rs, "1977m12") %>%
    mutate(cpi_u_early = if_else(date <= ym("1967m1"), cpi_u, NA)) %>%
    chain_to_base(cpi_u_early, cpi_u_x1, "1967m1") %>%
    mutate(cpi_u_late = if_else(date >= ym("1999m12"), c_cpi_u, NA)) %>%
    chain_to_base(cpi_u_late, cpi_u_rs, "1999m12") %>%
    mutate(value = case_when(
      date <= ym("1966m12") ~ cpi_u_early,
      date >= ym("1967m1") & date <= ym("1977m12") ~ cpi_u_x1,
      date >= ym("1978m1") & date <= ym("1999m12") ~ cpi_u_rs,
      date >= ym("2000m1") ~ cpi_u_late
    )) %>%
    select(year, month, c_cpi_u_extended = value)

  c_cpi_u_extended_monthly_nsa %>%
    write_csv(monthly_nsa_csv)

  usethis::use_data(c_cpi_u_extended_monthly_nsa, overwrite = TRUE)

  output_monthly <- c(monthly_nsa_csv, monthly_nsa_rda)

  ### ANNUAL
  annual_csv <- "data-raw/processed/c_cpi_u_extended_annual.csv"
  annual_rda <- "data/c_cpi_u_extended_annual.rda"

  c_cpi_u_extended_annual <- c_cpi_u_extended_monthly_nsa %>%
    filter(year <= 2022) %>%
    summarize(c_cpi_u_extended = mean(c_cpi_u_extended), .by = year) %>%
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) %>%
    arrange(year)

  c_cpi_u_extended_annual %>%
    write_csv(annual_csv)

  usethis::use_data(c_cpi_u_extended_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_annual)
  output
}
