export_dataset <- function(data, name) {
  csv_path <- paste0("data-raw/processed/", name, ".csv")
  rda_path <- paste0("data/", name, ".rda")

  write_csv(data, csv_path)

  assign(name, data, envir = environment())
  rlang::inject(usethis::use_data(!!sym(name), overwrite = TRUE))

  c(csv_path, rda_path)
}
