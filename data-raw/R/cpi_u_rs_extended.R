create_cpi_u_rs_extended <- function(cpi_u_data, cpi_u_x1_data, cpi_u_rs_data) {
  cpi_u_path <- tar_read(cpi_u_data) %>%
    str_subset("cpi_u_monthly_nsa.rda")
  cpi_u_x1_path <- tar_read(cpi_u_x1_data) %>%
    str_subset("cpi_u_x1_monthly_nsa.rda")
  cpi_u_rs_path <- tar_read(cpi_u_rs_data) %>%
    str_subset("cpi_u_rs_monthly_nsa.rda")

  load(cpi_u_path)
  load(cpi_u_x1_path)
  load(cpi_u_rs_path)

  ### MONTHLY
  monthly_nsa_csv <- "data-raw/processed/cpi_u_rs_extended_monthly_nsa.csv"
  monthly_nsa_rda <- "data/cpi_u_rs_extended_monthly_nsa.rda"

  cpi_u_rs_extended_monthly_nsa <- cpi_u_monthly_nsa %>%
    full_join(cpi_u_x1_monthly_nsa, by = c("year", "month")) %>%
    full_join(cpi_u_rs_monthly_nsa, by = c("year", "month")) %>%
    mutate(date = ym(paste(year, month))) %>%
    chain_to_base(cpi_u_x1, cpi_u_rs, "1977m12") %>%
    mutate(cpi_u_early = if_else(date <= ym("1967m1"), cpi_u, NA)) %>%
    chain_to_base(cpi_u_early, cpi_u_x1, "1967m1") %>%
    mutate(cpi_u_late = if_else(date >= ym("2022m12"), cpi_u, NA)) %>%
    chain_to_base(cpi_u_late, cpi_u_rs, "2022m12") %>%
    mutate(value = case_when(
      date <= ym("1966m12") ~ cpi_u_early,
      date >= ym("1967m1") & date <= ym("1977m12") ~ cpi_u_x1,
      date >= ym("1978m1") & date <= ym("2022m12") ~ cpi_u_rs,
      date >= ym("2023m1") ~ cpi_u_late
    )) %>%
    select(year, month, cpi_u_rs_extended = value)

  cpi_u_rs_extended_monthly_nsa %>%
    write_csv(monthly_nsa_csv)

  usethis::use_data(cpi_u_rs_extended_monthly_nsa, overwrite = TRUE)

  output_monthly <- c(monthly_nsa_csv, monthly_nsa_rda)

  ### ANNUAL
  annual_csv <- "data-raw/processed/cpi_u_rs_extended_annual.csv"
  annual_rda <- "data/cpi_u_rs_extended_annual.rda"

  cpi_u_rs_extended_annual <- cpi_u_rs_extended_monthly_nsa %>%
    filter(year <= 2022) %>%
    summarize(cpi_u_rs_extended = mean(cpi_u_rs_extended), .by = year) %>%
    mutate(cpi_u_rs_extended = round(cpi_u_rs_extended, digits = 1)) %>%
    arrange(year)

  cpi_u_rs_extended_annual %>%
    write_csv(annual_csv)

  usethis::use_data(cpi_u_rs_extended_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_annual)
  output
}


chain_to_base <- function(data, series_to_chain, base_series, base_date) {
  # root value of new base series
  base_series_0 <- data %>%
    filter(date == ym(base_date)) %>%
    pull({{base_series}})

  # root value of old series to be chained
  series_to_chain_0 <- data %>%
    filter(date == ym(base_date)) %>%
    pull({{series_to_chain}})

  # chain the series
  data %>%
    mutate({{series_to_chain}} := {{series_to_chain}} / series_to_chain_0) %>%
    mutate({{series_to_chain}} := {{series_to_chain}} * base_series_0)
}
