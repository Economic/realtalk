## Load your packages, e.g. library(targets).
source("data-raw/packages.R")

## Functions
lapply(list.files("./data-raw/R", full.names = TRUE), source)

tar_plan(
  # raw data
  tar_file(cpi_u_x1_raw, "data-raw/raw/cpi_u_x1.csv"),
  tar_file(cpi_u_sa_raw, "data-raw/raw/cpi_u_sa.csv"),
  tar_file(cpi_u_nsa_raw, "data-raw/raw/cpi_u_nsa.csv"),
  tar_file(cpi_u_rs_raw, "data-raw/raw/r-cpi-u-rs-allitems.csv"),

  # final data: csv and package data
  tar_file(cpi_u_x1_data, create_cpi_u_x1(cpi_u_x1_raw)),
  tar_file(cpi_u_rs_data, create_cpi_u_rs(cpi_u_rs_raw)),
  tar_file(cpi_u_data, create_cpi_u(cpi_u_nsa_raw, cpi_u_sa_raw)),
  tar_file(cpi_u_rs_extended_data, create_cpi_u_rs_extended(
    cpi_u_data, cpi_u_x1_data, cpi_u_rs_data
  ))
)

