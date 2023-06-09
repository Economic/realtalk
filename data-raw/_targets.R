## Load your packages, e.g. library(targets).
source("data-raw/packages.R")

## Functions
lapply(list.files("./data-raw/R", full.names = TRUE), source)

tar_plan(
  # raw data
  tar_file(cpi_u_x1_raw, "data-raw/raw/cpi_u_x1.csv"),
  tar_file(cpi_u_sa_raw, "data-raw/raw/cpi_u_sa.csv"),
  tar_file(cpi_u_nsa_raw, "data-raw/raw/cpi_u_nsa.csv"),
  tar_file(c_cpi_u_raw, "data-raw/raw/c_cpi_u_nsa.csv"),
  tar_file(cpi_u_rs_raw, "data-raw/raw/r-cpi-u-rs-allitems.csv"),
  tar_file(pce_monthly_raw, "data-raw/raw/pce_monthly_sa.csv"),
  tar_file(pce_annual_raw, "data-raw/raw/pce_annual.csv"),

  # final data: csv and package data
  tar_file(cpi_u_x1_data, create_cpi_u_x1(cpi_u_x1_raw)),
  tar_file(cpi_u_rs_data, create_cpi_u_rs(cpi_u_rs_raw)),
  tar_file(c_cpi_u_data, create_c_cpi_u(c_cpi_u_raw)),
  tar_file(cpi_u_data, create_cpi_u(cpi_u_nsa_raw, cpi_u_sa_raw)),
  tar_file(cpi_u_rs_extended_data, create_cpi_u_rs_extended(
    cpi_u_data, cpi_u_x1_data, cpi_u_rs_data
  )),
  tar_file(pce_data, create_pce(pce_monthly_raw, pce_annual_raw)),

  # all available data
  tar_file(available_data, catalog_data(
    cpi_u_data,
    c_cpi_u_data,
    cpi_u_x1_data,
    cpi_u_rs_data,
    cpi_u_rs_extended_data,
    pce_data
  ))
)


