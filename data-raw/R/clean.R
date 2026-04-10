clean_bls_monthly <- function(csv, col_name) {
  read_csv(csv, show_col_types = FALSE) |>
    select(year, month, !!col_name := value) |>
    arrange(year, month)
}

clean_c_cpi_u <- function(csv, known_missing) {
  clean_bls_monthly(csv, "c_cpi_u") |>
    add_missing_month_rows(c_cpi_u, known_missing)
}

clean_cpi_u_x1 <- function(csv) {
  read_csv(csv, show_col_types = FALSE) |>
    rename_with(tolower) |>
    select(-aavg) |>
    pivot_longer(-year, names_to = "month", values_to = "cpi_u_x1") |>
    mutate(month = month(ym(paste(year, month)))) |>
    filter(!is.na(cpi_u_x1)) |>
    arrange(year, month)
}

clean_cpi_u_rs <- function(csv, known_missing = NULL) {
  raw <- read_csv(
    csv,
    show_col_types = FALSE,
    col_types = cols(.default = "c")
  ) |>
    rename_with(tolower) |>
    select(-avg) |>
    pivot_longer(-year, names_to = "month_name", values_to = "cpi_u_rs") |>
    mutate(
      month = month(ym(paste(year, month_name))),
      year = as.integer(year)
    )

  if (!is.null(known_missing)) {
    missing_ym <- tibble(
      year = year(as.Date(known_missing, origin = "1970-01-01")),
      month = month(as.Date(known_missing, origin = "1970-01-01"))
    )
    raw <- raw |>
      mutate(
        cpi_u_rs = if_else(
          paste(year, month) %in% paste(missing_ym$year, missing_ym$month),
          NA_character_,
          cpi_u_rs
        )
      )
  }

  non_na <- raw |> filter(!is.na(cpi_u_rs))
  parsed <- suppressWarnings(as.numeric(non_na$cpi_u_rs))
  bad_rows <- which(is.na(parsed))
  if (length(bad_rows) > 0) {
    bad_vals <- unique(non_na$cpi_u_rs[bad_rows])
    cli_abort("Non-numeric values found in CPI-U-RS data: {bad_vals}")
  }

  raw |>
    mutate(cpi_u_rs = as.numeric(cpi_u_rs)) |>
    filter(!is.na(cpi_u_rs)) |>
    select(year, month, cpi_u_rs) |>
    arrange(year, month)
}

clean_pce <- function(csv) {
  read_csv(csv, show_col_types = FALSE)
}

clean_pce_quarterly <- function(csv) {
  read_csv(csv, show_col_types = FALSE)
}

clean_pce_annual <- function(csv) {
  read_csv(csv, show_col_types = FALSE)
}
