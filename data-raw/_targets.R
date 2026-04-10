source("./data-raw/packages.R")
tar_source("./data-raw/R")

## Known missing months (October 2025 BLS shutdown)
bls_missing <- c(ym("2025m10"))

tar_assign({
  ## ── Static file inputs ──
  us_minimum_wage_raw <- "data-raw/raw/us_minimum_wage.csv" |> tar_file()
  cpi_u_x1_raw <- "data-raw/raw/cpi_u_x1.csv" |> tar_file()
  cpi_u_rs_raw <- "data-raw/raw/r-cpi-u-rs-allitems.csv" |> tar_file()

  ## ── API fetches (re-run daily) ──
  cpi_u_nsa_raw <- fetch_cpi_u_nsa() |> tar_age_date()
  cpi_u_sa_raw <- fetch_cpi_u_sa() |> tar_age_date()
  c_cpi_u_raw <- fetch_c_cpi_u() |> tar_age_date()
  pce_monthly_raw <- fetch_pce_monthly_sa() |> tar_age_date()
  pce_quarterly_raw <- fetch_pce_quarterly_sa() |> tar_age_date()
  pce_annual_raw <- fetch_pce_annual() |> tar_age_date()

  ## ── Clean monthly series ──
  cpi_u_monthly_nsa <- clean_bls_monthly(cpi_u_nsa_raw, "cpi_u") |> tar_target()
  cpi_u_monthly_sa <- clean_bls_monthly(cpi_u_sa_raw, "cpi_u") |> tar_target()
  c_cpi_u_monthly_nsa <- clean_c_cpi_u(c_cpi_u_raw, bls_missing) |> tar_target()
  cpi_u_x1_monthly_nsa <- clean_cpi_u_x1(cpi_u_x1_raw) |> tar_target()
  cpi_u_rs_monthly_nsa <- clean_cpi_u_rs(cpi_u_rs_raw, bls_missing) |>
    tar_target()
  pce_monthly_sa <- clean_pce(pce_monthly_raw) |> tar_target()

  ## ── Aggregate: quarterly ──
  cpi_u_quarterly_nsa <- monthly_to_quarterly(
    cpi_u_monthly_nsa,
    cpi_u,
    known_missing = bls_missing
  ) |>
    tar_target()

  cpi_u_quarterly_sa <- monthly_to_quarterly(
    cpi_u_monthly_sa,
    cpi_u,
    known_missing = bls_missing
  ) |>
    tar_target()

  c_cpi_u_quarterly_nsa <- monthly_to_quarterly(
    c_cpi_u_monthly_nsa,
    c_cpi_u,
    known_missing = bls_missing
  ) |>
    tar_target()

  pce_quarterly_sa <- clean_pce_quarterly(pce_quarterly_raw) |>
    tar_target()

  ## ── Aggregate: annual ──
  cpi_u_annual <- monthly_to_annual(
    cpi_u_monthly_nsa,
    cpi_u,
    known_missing = bls_missing
  ) |>
    tar_target()

  c_cpi_u_annual <- monthly_to_annual(
    c_cpi_u_monthly_nsa,
    c_cpi_u,
    known_missing = bls_missing
  ) |>
    tar_target()

  cpi_u_x1_annual <- monthly_to_annual(cpi_u_x1_monthly_nsa, cpi_u_x1) |>
    tar_target()

  cpi_u_rs_annual <- monthly_to_annual(
    cpi_u_rs_monthly_nsa,
    cpi_u_rs,
    known_missing = bls_missing
  ) |>
    tar_target()

  pce_annual <- clean_pce_annual(pce_annual_raw) |> tar_target()

  ## ── Extended C-CPI-U ──
  c_cpi_u_extended_annual <- create_c_cpi_u_extended_annual(
    c_cpi_u_annual,
    cpi_u_annual,
    cpi_u_x1_annual,
    cpi_u_rs_annual
  ) |>
    tar_target()

  c_cpi_u_extended_monthly_nsa <- create_c_cpi_u_extended_monthly_nsa(
    c_cpi_u_extended_annual,
    c_cpi_u_monthly_nsa,
    cpi_u_monthly_nsa,
    cpi_u_annual,
    cpi_u_x1_monthly_nsa,
    cpi_u_x1_annual,
    cpi_u_rs_monthly_nsa,
    cpi_u_rs_annual,
    known_missing = bls_missing
  ) |>
    tar_target()

  c_cpi_u_extended_monthly_sa <- create_c_cpi_u_extended_monthly_sa(
    c_cpi_u_extended_monthly_nsa,
    cpi_u_monthly_nsa,
    cpi_u_monthly_sa,
    known_missing = bls_missing
  ) |>
    tar_target()

  c_cpi_u_extended_quarterly_nsa <- monthly_to_quarterly(
    c_cpi_u_extended_monthly_nsa,
    c_cpi_u_extended,
    known_missing = bls_missing
  ) |>
    tar_target()

  c_cpi_u_extended_quarterly_sa <- monthly_to_quarterly(
    c_cpi_u_extended_monthly_sa,
    c_cpi_u_extended,
    known_missing = bls_missing
  ) |>
    tar_target()

  ## ── Minimum wage ──
  us_minimum_wage_monthly <- create_fed_mw_monthly(us_minimum_wage_raw) |>
    tar_target()
  us_minimum_wage_annual <- create_fed_mw_annual(us_minimum_wage_monthly) |>
    tar_target()

  ## ── Export all datasets (CSV + .rda) ──
  cpi_u_monthly_nsa_out <- export_dataset(
    cpi_u_monthly_nsa,
    "cpi_u_monthly_nsa"
  ) |>
    tar_file()
  cpi_u_monthly_sa_out <- export_dataset(
    cpi_u_monthly_sa,
    "cpi_u_monthly_sa"
  ) |>
    tar_file()
  cpi_u_quarterly_nsa_out <- export_dataset(
    cpi_u_quarterly_nsa,
    "cpi_u_quarterly_nsa"
  ) |>
    tar_file()
  cpi_u_quarterly_sa_out <- export_dataset(
    cpi_u_quarterly_sa,
    "cpi_u_quarterly_sa"
  ) |>
    tar_file()
  cpi_u_annual_out <- export_dataset(cpi_u_annual, "cpi_u_annual") |> tar_file()

  c_cpi_u_monthly_nsa_out <- export_dataset(
    c_cpi_u_monthly_nsa,
    "c_cpi_u_monthly_nsa"
  ) |>
    tar_file()
  c_cpi_u_quarterly_nsa_out <- export_dataset(
    c_cpi_u_quarterly_nsa,
    "c_cpi_u_quarterly_nsa"
  ) |>
    tar_file()
  c_cpi_u_annual_out <- export_dataset(c_cpi_u_annual, "c_cpi_u_annual") |>
    tar_file()

  c_cpi_u_extended_annual_out <- export_dataset(
    c_cpi_u_extended_annual,
    "c_cpi_u_extended_annual"
  ) |>
    tar_file()
  c_cpi_u_extended_monthly_nsa_out <- export_dataset(
    c_cpi_u_extended_monthly_nsa,
    "c_cpi_u_extended_monthly_nsa"
  ) |>
    tar_file()
  c_cpi_u_extended_monthly_sa_out <- export_dataset(
    c_cpi_u_extended_monthly_sa,
    "c_cpi_u_extended_monthly_sa"
  ) |>
    tar_file()
  c_cpi_u_extended_quarterly_nsa_out <- export_dataset(
    c_cpi_u_extended_quarterly_nsa,
    "c_cpi_u_extended_quarterly_nsa"
  ) |>
    tar_file()
  c_cpi_u_extended_quarterly_sa_out <- export_dataset(
    c_cpi_u_extended_quarterly_sa,
    "c_cpi_u_extended_quarterly_sa"
  ) |>
    tar_file()

  cpi_u_x1_monthly_nsa_out <- export_dataset(
    cpi_u_x1_monthly_nsa,
    "cpi_u_x1_monthly_nsa"
  ) |>
    tar_file()

  cpi_u_x1_annual_out <- export_dataset(cpi_u_x1_annual, "cpi_u_x1_annual") |>
    tar_file()

  cpi_u_rs_monthly_nsa_out <- export_dataset(
    cpi_u_rs_monthly_nsa,
    "cpi_u_rs_monthly_nsa"
  ) |>
    tar_file()

  cpi_u_rs_annual_out <- export_dataset(cpi_u_rs_annual, "cpi_u_rs_annual") |>
    tar_file()

  pce_monthly_sa_out <- export_dataset(pce_monthly_sa, "pce_monthly_sa") |>
    tar_file()

  pce_quarterly_sa_out <- export_dataset(
    pce_quarterly_sa,
    "pce_quarterly_sa"
  ) |>
    tar_file()

  pce_annual_out <- export_dataset(pce_annual, "pce_annual") |> tar_file()

  us_minimum_wage_monthly_out <- export_dataset(
    us_minimum_wage_monthly,
    "us_minimum_wage_monthly"
  ) |>
    tar_file()

  us_minimum_wage_annual_out <- export_dataset(
    us_minimum_wage_annual,
    "us_minimum_wage_annual"
  ) |>
    tar_file()

  ## ── Catalog ──
  available_data <- catalog_data(
    cpi_u_monthly_nsa_out,
    cpi_u_monthly_sa_out,
    cpi_u_quarterly_nsa_out,
    cpi_u_quarterly_sa_out,
    cpi_u_annual_out,
    c_cpi_u_monthly_nsa_out,
    c_cpi_u_quarterly_nsa_out,
    c_cpi_u_annual_out,
    c_cpi_u_extended_annual_out,
    c_cpi_u_extended_monthly_nsa_out,
    c_cpi_u_extended_monthly_sa_out,
    c_cpi_u_extended_quarterly_nsa_out,
    c_cpi_u_extended_quarterly_sa_out,
    cpi_u_x1_monthly_nsa_out,
    cpi_u_x1_annual_out,
    cpi_u_rs_monthly_nsa_out,
    cpi_u_rs_annual_out,
    pce_monthly_sa_out,
    pce_quarterly_sa_out,
    pce_annual_out
  ) |>
    tar_file()
})
