create_c_cpi_u_extended <- function(cpi_u_data, cpi_u_x1_data, cpi_u_rs_data, c_cpi_u_data) {

  cpi_u_nsa_path <- tar_read(cpi_u_data) %>%
    str_subset("cpi_u_monthly_nsa.rda")
  cpi_u_sa_path <- tar_read(cpi_u_data) %>%
    str_subset("cpi_u_monthly_sa.rda")
  cpi_u_annual_path <- tar_read(cpi_u_data) %>%
    str_subset("cpi_u_annual.rda")
  cpi_u_x1_monthly_path <- tar_read(cpi_u_x1_data) %>%
    str_subset("cpi_u_x1_monthly_nsa.rda")
  cpi_u_x1_annual_path <- tar_read(cpi_u_x1_data) %>%
    str_subset("cpi_u_x1_annual.rda")
  cpi_u_rs_monthly_path <- tar_read(cpi_u_rs_data) %>%
    str_subset("cpi_u_rs_monthly_nsa.rda")
  cpi_u_rs_annual_path <- tar_read(cpi_u_rs_data) %>%
    str_subset("cpi_u_rs_annual.rda")
  c_cpi_u_monthly_path <- tar_read(c_cpi_u_data) %>%
    str_subset("c_cpi_u_monthly_nsa.rda")
  c_cpi_u_quarterly_path <- tar_read(c_cpi_u_data) %>%
    str_subset("c_cpi_u_quarterly_nsa.rda")
  c_cpi_u_annual_path <- tar_read(c_cpi_u_data) %>%
    str_subset("c_cpi_u_annual.rda")

  load(cpi_u_nsa_path)
  load(cpi_u_sa_path)
  load(cpi_u_annual_path)
  load(cpi_u_x1_monthly_path)
  load(cpi_u_x1_annual_path)
  load(cpi_u_rs_monthly_path)
  load(cpi_u_rs_annual_path)
  load(c_cpi_u_monthly_path)
  load(c_cpi_u_quarterly_path)
  load(c_cpi_u_annual_path)

  ### ANNUAL
  annual_csv <- "data-raw/processed/c_cpi_u_extended_annual.csv"
  annual_rda <- "data/c_cpi_u_extended_annual.rda"

  c_cpi_u_extended_annual = c_cpi_u_annual |>
    full_join(cpi_u_annual, by = "year") |>
    full_join(cpi_u_x1_annual, by = "year") |>
    full_join(cpi_u_rs_annual, by = "year") |>
    mutate(cpi_late = if_else(year >= 2000, c_cpi_u, NA)) |>
    mutate(cpi_early = if_else(year <= 1967, cpi_u, NA)) |>
    chain_to_base_annual(cpi_u_rs, cpi_late, 2000) |>
    chain_to_base_annual(cpi_u_x1, cpi_u_rs, 1978) |>
    chain_to_base_annual(cpi_early, cpi_u_x1, 1967) |>
    mutate(value = case_when(
      year <= 1966 ~ cpi_early,
      year >= 1967 & year <= 1977 ~ cpi_u_x1,
      year >= 1978 & year <= 1999 ~ cpi_u_rs,
      year >= 2000 ~ cpi_late
    )) |>
    select(year, c_cpi_u_extended = value) |>
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) |>
    arrange(year)

  c_cpi_u_extended_annual %>%
    write_csv(annual_csv)

  usethis::use_data(c_cpi_u_extended_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### MONTHLY
  monthly_nsa_csv <- "data-raw/processed/c_cpi_u_extended_monthly_nsa.csv"
  monthly_nsa_rda <- "data/c_cpi_u_extended_monthly_nsa.rda"
  monthly_sa_csv <- "data-raw/processed/c_cpi_u_extended_monthly_sa.csv"
  monthly_sa_rda <- "data/c_cpi_u_extended_monthly_sa.rda"

  cpi_u_ann_ratio = cpi_u_monthly_nsa |>
    rename(cpi_u_monthly = cpi_u) |>
    inner_join(cpi_u_annual, by = "year") |>
    rename(cpi_u_annual = cpi_u) |>
    mutate(cpi_u_ratio = cpi_u_monthly / cpi_u_annual) |>
    select(year, month, cpi_u_ratio)

  cpi_u_x1_ann_ratio = cpi_u_x1_monthly_nsa |>
    rename(cpi_u_x1_monthly = cpi_u_x1) |>
    inner_join(cpi_u_x1_annual, by = "year") |>
    rename(cpi_u_x1_annual = cpi_u_x1) |>
    mutate(cpi_u_x1_ratio = cpi_u_x1_monthly / cpi_u_x1_annual) |>
    select(year, month, cpi_u_x1_ratio)

  cpi_u_rs_ann_ratio = cpi_u_rs_monthly_nsa |>
    rename(cpi_u_rs_monthly = cpi_u_rs) |>
    inner_join(cpi_u_rs_annual, by = "year") |>
    rename(cpi_u_rs_annual = cpi_u_rs) |>
    mutate(cpi_u_rs_ratio = cpi_u_rs_monthly / cpi_u_rs_annual) |>
    select(year, month, cpi_u_rs_ratio)

  c_cpi_u_ann_ratio = c_cpi_u_monthly_nsa |>
    rename(c_cpi_u_monthly = c_cpi_u) |>
    inner_join(c_cpi_u_annual, by = "year") |>
    rename(c_cpi_u_annual = c_cpi_u) |>
    mutate(c_cpi_u_ratio = c_cpi_u_monthly / c_cpi_u_annual) |>
    select(year, month, c_cpi_u_ratio)

  c_cpi_u_extended_monthly_nsa = cpi_u_ann_ratio |>
    full_join(cpi_u_x1_ann_ratio, by = c("year", "month")) |>
    full_join(cpi_u_rs_ann_ratio, by = c("year", "month")) |>
    full_join(c_cpi_u_monthly_nsa, by = c("year", "month")) |>
    rename(cpi_monthly = c_cpi_u) |>
    full_join(c_cpi_u_extended_annual, by = "year") |>
    rename(cpi_annual = c_cpi_u_extended) |>
    mutate(value = case_when(
      year <= 1966 ~ cpi_u_ratio * cpi_annual,
      year >= 1967 & year <= 1977 ~ cpi_u_x1_ratio * cpi_annual,
      year >= 1978 & year <= 1999 ~ cpi_u_rs_ratio * cpi_annual,
      year >= 2000 ~ cpi_monthly
    )) |>
    select(year, month, c_cpi_u_extended = value) |>
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) |>
    arrange(year, month)

  c_cpi_u_extended_monthly_sa <- cpi_u_monthly_nsa %>%
    rename(cpi_u_nsa = cpi_u) %>%
    inner_join(cpi_u_monthly_sa, by = c("year", "month")) %>%
    rename(cpi_u_sa = cpi_u) %>%
    inner_join(c_cpi_u_extended_monthly_nsa, by = c("year", "month")) %>%
    mutate(
      sa_factor = cpi_u_sa / cpi_u_nsa,
      c_cpi_u_extended = c_cpi_u_extended * sa_factor
    ) %>%
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


}
