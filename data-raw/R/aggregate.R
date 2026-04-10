monthly_to_annual <- function(data, value_col, known_missing = NULL) {
  if (is.null(known_missing)) {
    missing_by_year <- tibble(year = integer(), n_missing = integer())
  } else {
    missing_by_year <- tibble(date = known_missing) |>
      mutate(year = year(date)) |>
      summarize(n_missing = n(), .by = year)
  }

  data |>
    left_join(missing_by_year, by = "year") |>
    mutate(n_missing = replace_na(n_missing, 0L)) |>
    mutate(
      month_count = sum(!is.na({{ value_col }})),
      expected = 12L - n_missing,
      .by = year
    ) |>
    filter(month_count >= expected) |>
    summarize(
      {{ value_col }} := mean({{ value_col }}, na.rm = TRUE),
      .by = year
    ) |>
    mutate({{ value_col }} := round({{ value_col }}, digits = 1)) |>
    arrange(year)
}

monthly_to_quarterly <- function(data, value_col, known_missing = NULL) {
  if (is.null(known_missing)) {
    missing_by_qtr <- tibble(
      year = integer(),
      quarter = integer(),
      n_missing = integer()
    )
  } else {
    missing_by_qtr <- tibble(date = known_missing) |>
      mutate(year = year(date), quarter = quarter(date)) |>
      summarize(n_missing = n(), .by = c(year, quarter))
  }

  data |>
    mutate(quarter = quarter(month)) |>
    left_join(missing_by_qtr, by = c("year", "quarter")) |>
    mutate(n_missing = replace_na(n_missing, 0L)) |>
    mutate(
      month_count = sum(!is.na({{ value_col }})),
      expected = 3L - n_missing,
      .by = c(year, quarter)
    ) |>
    filter(month_count >= expected) |>
    summarize(
      {{ value_col }} := mean({{ value_col }}, na.rm = TRUE),
      .by = c(year, quarter)
    ) |>
    mutate({{ value_col }} := round({{ value_col }}, digits = 1)) |>
    arrange(year, quarter)
}
