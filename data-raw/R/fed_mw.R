create_fed_mw_monthly <- function(raw_csv) {
  final_yearmonth_date <- "2026m2"
  current_fed_mw <- 7.25

  raw_csv |>
    read_csv(show_col_types = FALSE) |>
    mutate(date = yearmonth(mdy(date))) |>
    add_row(
      date = yearmonth(final_yearmonth_date),
      fed_min_wage = current_fed_mw
    ) |>
    as_tsibble(index = date) |>
    fill_gaps() |>
    as_tibble() |>
    arrange(date) |>
    fill(fed_min_wage, .direction = "down") |>
    transmute(
      year = year(date),
      month = month(date),
      minimum_wage = fed_min_wage
    )
}

create_fed_mw_annual <- function(monthly_mw_data) {
  monthly_mw_data |>
    summarize(minimum_wage = max(minimum_wage), .by = year) |>
    arrange(year)
}
