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
