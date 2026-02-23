library(tidyverse)

create_fed_mw_annual <- function(raw_csv) {

  mw_csv <- "data-raw/processed/us_minimum_wage_annual.csv"
  mw_rda <- "data/us_minimum_wage_annual.rda"

  years_data <- enframe(1938:2026, name = NULL, value = "year")

  us_minimum_wage <- raw_csv %>%
    read_csv(show_col_types = FALSE) %>%
    mutate(year = year(mdy(date))) %>%
    summarize(minimum_wage = max(fed_min_wage), .by = year) %>%
    full_join(years_data, by = "year") %>%
    arrange(year) %>%
    fill(minimum_wage)

  us_minimum_wage %>%
    write_csv(mw_csv)

  usethis::use_data(us_minimum_wage, overwrite = TRUE)

  output <- c(mw_csv, mw_rda)
  output
}

create_fed_mw_monthly <- function(raw_csv) {
  mw_csv <- "data-raw/processed/us_minimum_wage_monthly.csv"
  mw_rda <- "data/us_minimum_wage_monthly.rda"

  final_yearmonth_date <- "2026m2"
  current_fed_mw <- 7.25

  us_minimum_wage_monthly <- raw_csv %>%
    read_csv(show_col_types = FALSE) %>%
    mutate(date = yearmonth(mdy(date))) %>%
    add_row(date = yearmonth(final_yearmonth_date), fed_min_wage = current_fed_mw) %>%
    as_tsibble(index = date) %>%
    fill_gaps() %>%
    as_tibble() %>%
    arrange(date) %>%
    fill(fed_min_wage, .direction = "down") %>%
    transmute(
      year = year(date),
      month = month(date),
      minimum_wage = fed_min_wage
    )

  us_minimum_wage_monthly %>%
    write_csv(mw_csv)

  usethis::use_data(us_minimum_wage_monthly, overwrite = TRUE)

  us_minimum_wage_monthly
}

create_fed_mw_annual <- function(monthly_mw_data) {
  mw_csv <- "data-raw/processed/us_minimum_wage_annual.csv"
  mw_rda <- "data/us_minimum_wage_annual.rda"

  us_minimum_wage_annual <- monthly_mw_data %>%
    summarize(minimum_wage = max(minimum_wage), .by = year) %>%
    arrange(year)

  us_minimum_wage_annual %>%
    write_csv(mw_csv)

  usethis::use_data(us_minimum_wage_annual, overwrite = TRUE)

  output <- c(mw_csv, mw_rda)
  output
}


