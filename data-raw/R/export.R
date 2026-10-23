assert_unique_periods <- function(data) {
  time_cols <- intersect(c("year", "quarter", "month", "date"), names(data))
  if (length(time_cols) == 0) {
    cli_abort("No time period columns found in data.")
  }
  data |>
    assert_rows(col_concat, is_uniq, all_of(time_cols))
}

export_dataset <- function(data, name) {
  csv_path <- paste0("data-raw/processed/", name, ".csv")
  rda_path <- paste0("data/", name, ".rda")

  assert_unique_periods(data)
  write_csv(data, csv_path)

  assign(name, data, envir = environment())
  rlang::inject(usethis::use_data(!!sym(name), overwrite = TRUE))

  c(csv_path, rda_path)
}

export_known_missing_months <- function(months) {
  # Internal data, so the package's tests can check gaps against the same list
  # the pipeline uses
  known_missing_months <- tibble(
    year = as.integer(year(months)),
    month = as.integer(month(months))
  )
  usethis::use_data(known_missing_months, internal = TRUE, overwrite = TRUE)

  "R/sysdata.rda"
}
