# Hello, world!
#
# This is an example function named 'hello'
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'

hello <- function() {
  print("Hello, world!")
}


df %>%
  mutate(real_wage = price_inflate(wage, "cpi_u_rs", "year", 2022))

df %>%
  mutate(real_wage = price_inflate(wage, "cpi_u_rs", c("year", "month"), 2022))


library(tidyverse)
library(lubridate)
library(blsR)
here::i_am("create_cpi.R")
library(here)

BLS_API_KEY <- Sys.getenv("BLS_API_KEY")

# CPI-U-NSA from BLS
cpi_u_nsa_raw <- get_series_table("CUUR0000SA0", BLS_API_KEY, start_year = 1937, end_year = 2023) %>%
  select(year, period, value)

# CPI-U-SA from BLS
cpi_u_sa_raw <- get_series_table("CUSR0000SA0", BLS_API_KEY, start_year = 1947, end_year = 2023) %>%
  select(year, period, value)

# CPI-U-X1 from Economic Report of the President, 2011, Table B-62
# https://www.govinfo.gov/content/pkg/ERP-2011/pdf/ERP-2011-table62.pdf
# hand-entered into cpi_u_x1.csv
cpi_u_x1_raw <- read_csv(here("data", "raw", "cpi_u_x1.csv")) %>%
  rename_all(tolower) %>%
  select(-aavg) %>%
  pivot_longer(-year, names_to = "month", values_to = "cpi_u_x1") %>%
  mutate(date = ym(paste(year, month))) %>%
  select(date, cpi_u_x1)

# CPI-U-RS from BLS
# https://www.bls.gov/cpi/research-series/r-cpi-u-rs-home.htm
# https://www.bls.gov/cpi/research-series/r-cpi-u-rs-allitems.xlsx
# hand-converted to r-cpi-u-rs-allitems.csv
cpi_u_rs_raw <- read_csv(here("data", "raw", "r-cpi-u-rs-allitems.csv")) %>%
  rename_all(tolower) %>%
  select(-avg) %>%
  pivot_longer(-year, names_to = "month", values_to = "cpi_u_rs") %>%
  mutate(date = ym(paste(year, month))) %>%
  select(date, cpi_u_rs)

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

cpi_u_nsa_raw %>%
  rename(cpi_u_nsa = value) %>%
  full_join(cpi_u_sa_raw, by = c("year", "period")) %>%
  rename(cpi_u_sa = value) %>%
  mutate(period = as.numeric(str_sub(period, 2, 3))) %>%
  filter(period >= 1 & period <= 12) %>%
  mutate(date = ym(paste(year, period))) %>%
  full_join(cpi_u_x1_raw, by = "date") %>%
  full_join(cpi_u_rs_raw, by = "date") %>%
  select(date, matches("cpi")) %>%
  arrange(date) %>%
  chain_to_base(cpi_u_x1, cpi_u_rs, "1977m12") %>%
  mutate(cpi_u_early = if_else(date <= ym("1967m1"), cpi_u_nsa, NA_real_)) %>%
  chain_to_base(cpi_u_early, cpi_u_x1, "1967m1") %>%
  mutate(cpi_u_late = if_else(date >= ym("2022m12"), cpi_u_nsa, NA_real_)) %>%
  chain_to_base(cpi_u_late, cpi_u_rs, "2022m12") %>%
  mutate(cpi_u_rs_nsa_extended = case_when(
    date <= ym("1966m12") ~ cpi_u_early,
    date >= ym("1967m1") & date <= ym("1977m12") ~ cpi_u_x1,
    date >= ym("1978m1") & date <= ym("2022m12") ~ cpi_u_rs,
    date >= ym("2023m1") ~ cpi_u_late
  )) %>%
  mutate(sa_factor = case_when(
    date >= ym("1947m1") ~ cpi_u_sa / cpi_u_nsa,
    date <  ym("1947m1") ~ 1
  )) %>%
  mutate(cpi_u_rs_sa_extended = cpi_u_rs_nsa_extended * sa_factor) %>%
  write_csv(here("data", "processed", "cpi_u_rs_extended.csv"))

