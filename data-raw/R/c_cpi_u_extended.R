create_c_cpi_u_extended <- function(cpi_u_data, cpi_u_x1_data, cpi_u_rs_data, c_cpi_u_data) {
  cpi_u_nsa_path <- tar_read(cpi_u_data) %>%
    str_subset("cpi_u_monthly_nsa.rda")
  cpi_u_sa_path <- tar_read(cpi_u_data) %>%
    str_subset("cpi_u_monthly_sa.rda")
  cpi_u_x1_path <- tar_read(cpi_u_x1_data) %>%
    str_subset("cpi_u_x1_monthly_nsa.rda")
  cpi_u_rs_path <- tar_read(cpi_u_rs_data) %>%
    str_subset("cpi_u_rs_monthly_nsa.rda")
  c_cpi_u_path <- tar_read(c_cpi_u_data) %>%
    str_subset("c_cpi_u_monthly_nsa.rda")

  load(cpi_u_nsa_path)
  load(cpi_u_sa_path)
  load(cpi_u_x1_path)
  load(cpi_u_rs_path)
  load(c_cpi_u_path)

  ### MONTHLY
  monthly_nsa_csv <- "data-raw/processed/c_cpi_u_extended_monthly_nsa.csv"
  monthly_nsa_rda <- "data/c_cpi_u_extended_monthly_nsa.rda"
  monthly_sa_csv <- "data-raw/processed/c_cpi_u_extended_monthly_sa.csv"
  monthly_sa_rda <- "data/c_cpi_u_extended_monthly_sa.rda"

  c_cpi_u_extended_monthly_nsa <- cpi_u_monthly_nsa %>%
    full_join(cpi_u_x1_monthly_nsa, by = c("year", "month")) %>%
    full_join(cpi_u_rs_monthly_nsa, by = c("year", "month")) %>%
    full_join(c_cpi_u_monthly_nsa, by = c("year", "month")) %>%
    mutate(date = ym(paste(year, month))) %>%
    mutate(cpi_u_late = if_else(date >= ym("1999m12"), c_cpi_u, NA)) %>%
    chain_to_base(cpi_u_rs, cpi_u_late, "1999m12") %>%
    chain_to_base(cpi_u_x1, cpi_u_rs, "1977m12") %>%
    mutate(cpi_u_early = if_else(date <= ym("1967m1"), cpi_u, NA)) %>%
    chain_to_base(cpi_u_early, cpi_u_x1, "1967m1") %>%
    mutate(value = case_when(
      date <= ym("1966m12") ~ cpi_u_early,
      date >= ym("1967m1") & date <= ym("1977m12") ~ cpi_u_x1,
      date >= ym("1978m1") & date <= ym("1999m12") ~ cpi_u_rs,
      date >= ym("2000m1") ~ cpi_u_late
    )) %>%
    select(year, month, c_cpi_u_extended = value) %>%
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) %>%
    arrange(year, month)

  c_cpi_u_extended_monthly_sa <- cpi_u_monthly_nsa %>%
    rename(cpi_u_nsa = cpi_u) %>%
    inner_join(cpi_u_monthly_sa, by = c("year", "month")) %>%
    rename(cpi_u_sa = cpi_u) %>%
    inner_join(c_cpi_u_extended_monthly_nsa, by = c("year", "month")) %>%
    mutate(date = ym(paste(year, month))) %>%
    mutate(sa_factor = cpi_u_sa / cpi_u_nsa) %>%
    mutate(c_cpi_u_extended = c_cpi_u_extended * sa_factor) %>%
    select(year, month, c_cpi_u_extended) %>%
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) %>%
    arrange(year, month)

  c_cpi_u_extended_monthly_nsa %>%
    write_csv(monthly_nsa_csv)

  c_cpi_u_extended_monthly_sa %>%
    write_csv(monthly_sa_csv)

  usethis::use_data(c_cpi_u_extended_monthly_nsa, overwrite = TRUE)
  usethis::use_data(c_cpi_u_extended_monthly_sa, overwrite = TRUE)

  output_monthly <- c(
    monthly_nsa_csv,
    monthly_nsa_rda,
    monthly_sa_csv,
    monthly_sa_rda
  )

  ### QUARTERLY
  quarterly_nsa_csv <- "data-raw/processed/c_cpi_u_extended_quarterly_nsa.csv"
  quarterly_nsa_rda <- "data/c_cpi_u_extended_quarterly_nsa.rda"
  quarterly_sa_csv <- "data-raw/processed/c_cpi_u_extended_quaterly_sa.csv"
  quarterly_sa_rda <- "data/c_cpi_u_extended_quarterly_sa.rda"

  c_cpi_u_extended_quarterly_sa <- c_cpi_u_extended_monthly_sa |>
    # only quarter-ize data where 3 months of values exist
    mutate(quarter = quarter(month)) |>
    mutate(month_count = sum(!is.na(month)), .by = c(year, quarter)) %>%
    filter(month_count == 3) %>%
    summarize(
      c_cpi_u_extended = mean(c_cpi_u_extended),
      .by = c(year, quarter)
    ) %>%
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) %>%
    arrange(year, quarter)

  c_cpi_u_extended_quarterly_nsa <- c_cpi_u_extended_monthly_nsa |>
    # only quarter-ize data where 3 months of values exist
    mutate(quarter = quarter(month)) |>
    mutate(month_count = sum(!is.na(month)), .by = c(year, quarter)) %>%
    filter(month_count == 3) %>%
    summarize(
      c_cpi_u_extended = mean(c_cpi_u_extended),
      .by = c(year, quarter)
    ) %>%
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) %>%
    arrange(year, quarter)

  c_cpi_u_extended_quarterly_nsa %>%
    write_csv(quarterly_nsa_csv)

  c_cpi_u_extended_quarterly_sa %>%
    write_csv(quarterly_sa_csv)

  usethis::use_data(c_cpi_u_extended_quarterly_nsa, overwrite = TRUE)
  usethis::use_data(c_cpi_u_extended_quarterly_sa, overwrite = TRUE)

  output_quarterly <- c(
    quarterly_nsa_csv,
    quarterly_nsa_rda,
    quarterly_sa_csv,
    quarterly_sa_rda
  )

  ### ANNUAL
  annual_csv <- "data-raw/processed/c_cpi_u_extended_annual.csv"
  annual_rda <- "data/c_cpi_u_extended_annual.rda"

  c_cpi_u_extended_annual <- c_cpi_u_extended_monthly_nsa %>%
    # only annualize data where 12 months of values exist
    mutate(month_count = sum(!is.na(month)), .by = year) %>%
    filter(month_count == 12) %>%
    summarize(c_cpi_u_extended = mean(c_cpi_u_extended), .by = year) %>%
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) %>%
    arrange(year)

  c_cpi_u_extended_annual %>%
    write_csv(annual_csv)

  usethis::use_data(c_cpi_u_extended_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_quarterly, output_annual)
  output
}
