library(tidyverse)

create_fed_mw <- function(raw_csv) {

  mw_csv <- "data-raw/processed/us_minimum_wage.csv"
  mw_rda <- "data/us_minimum_wage.rda"

  years_data <- enframe(1938:2022, name = NULL, value = "year")

  us_minimum_wage <- raw_csv %>%
    read_csv(show_col_types = FALSE) %>%
    mutate(year = year(mdy(date))) %>%
    summarize(minimum_wage = max(fed_min_wage), .by = year) %>%
    add_row(year = 2022, minimum_wage = 7.25) %>%
    full_join(years_data, by = "year") %>%
    arrange(year) %>%
    fill(minimum_wage)

  us_minimum_wage %>%
    write_csv(mw_csv)

  usethis::use_data(us_minimum_wage, overwrite = TRUE)

  output <- c(mw_csv, mw_rda)
  output
}


