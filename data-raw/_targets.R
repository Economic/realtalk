## Load your packages, e.g. library(targets).
source("data-raw/packages.R")

## Globals
download_date <- ymd("2025-03-12")

## Functions
lapply(list.files("./data-raw/R", full.names = TRUE), source)

tar_plan(
  # raw data files
  tar_file(us_minimum_wage_raw, "data-raw/raw/us_minimum_wage.csv"),
  tar_file(cpi_u_x1_raw, "data-raw/raw/cpi_u_x1.csv"),
  tar_file(cpi_u_rs_raw, "data-raw/raw/r-cpi-u-rs-allitems.csv"),
  tar_file(cpi_u_sa_raw, fetch_cpi_u_sa(download_date)),
  tar_file(cpi_u_nsa_raw, fetch_cpi_u_nsa(download_date)),
  tar_file(c_cpi_u_raw, fetch_c_cpi_u(download_date)),
  tar_file(pce_monthly_raw, fetch_pce_monthly_sa(download_date)),
  tar_file(pce_quarterly_raw, fetch_pce_quarterly_sa(download_date)),
  tar_file(pce_annual_raw, fetch_pce_annual(download_date)),

  # final data: csv and package data
  tar_file(cpi_u_x1_data, create_cpi_u_x1(cpi_u_x1_raw)),
  tar_file(cpi_u_rs_data, create_cpi_u_rs(cpi_u_rs_raw)),
  tar_file(c_cpi_u_data, create_c_cpi_u(c_cpi_u_raw)),
  tar_file(cpi_u_data, create_cpi_u(cpi_u_nsa_raw, cpi_u_sa_raw)),
  tar_file(c_cpi_u_extended_data, create_c_cpi_u_extended(
    cpi_u_data, cpi_u_x1_data, cpi_u_rs_data, c_cpi_u_data
  )),
  tar_file(pce_data, create_pce(pce_monthly_raw, pce_quarterly_raw, pce_annual_raw)),
  tar_target(fed_mw_monthly_data, create_fed_mw_monthly(us_minimum_wage_raw)),
  tar_file(fed_mw_annual_data, create_fed_mw_annual(fed_mw_monthly_data)),

  # all available data
  tar_file(available_data, catalog_data(
    cpi_u_data,
    c_cpi_u_data,
    c_cpi_u_extended_data,
    cpi_u_x1_data,
    cpi_u_rs_data,
    pce_data
  ))
)


