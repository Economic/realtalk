interpolate_missing_months <- function(data, variable, months_to_interpolate) {
  for (m in months_to_interpolate) {
    m <- as.Date(m, origin = "1970-01-01")
    y <- year(m)
    mo <- month(m)

    prev_mo <- if (mo == 1) 12 else mo - 1
    prev_y <- if (mo == 1) y - 1 else y
    next_mo <- if (mo == 12) 1 else mo + 1
    next_y <- if (mo == 12) y + 1 else y

    val_prev <- data |>
      filter(year == prev_y, month == prev_mo) |>
      pull({{ variable }})
    val_next <- data |>
      filter(year == next_y, month == next_mo) |>
      pull({{ variable }})

    if (
      length(val_prev) == 1 &&
        length(val_next) == 1 &&
        !is.na(val_prev) &&
        !is.na(val_next)
    ) {
      data <- data |>
        mutate(
          {{ variable }} := if_else(
            year == y & month == mo,
            (val_prev + val_next) / 2,
            {{ variable }}
          )
        )
    }
  }

  data
}

add_missing_month_rows <- function(data, variable, months) {
  for (m in months) {
    m <- as.Date(m, origin = "1970-01-01")
    y <- year(m)
    mo <- month(m)

    row_exists <- any(data$year == y & data$month == mo)
    if (!row_exists) {
      new_row <- tibble(year = y, month = mo, {{ variable }} := NA_real_)
      data <- bind_rows(data, new_row) |>
        arrange(year, month)
    }
  }

  data
}

chain_to_base <- function(data, series_to_chain, base_series, base_date) {
  # root value of new base series
  base_series_0 <- data %>%
    filter(date == ym(base_date)) %>%
    pull({{ base_series }})

  # root value of old series to be chained
  series_to_chain_0 <- data %>%
    filter(date == ym(base_date)) %>%
    pull({{ series_to_chain }})

  # chain the series
  data %>%
    mutate(
      {{ series_to_chain }} := {{ series_to_chain }} / series_to_chain_0
    ) %>%
    mutate({{ series_to_chain }} := {{ series_to_chain }} * base_series_0)
}

chain_to_base_annual <- function(
  data,
  series_to_chain,
  base_series,
  base_year
) {
  # root value of new base series
  base_series_0 <- data %>%
    filter(year == base_year) %>%
    pull({{ base_series }})

  # root value of old series to be chained
  series_to_chain_0 <- data %>%
    filter(year == base_year) %>%
    pull({{ series_to_chain }})

  # chain the series
  data %>%
    mutate(
      {{ series_to_chain }} := {{ series_to_chain }} / series_to_chain_0
    ) %>%
    mutate({{ series_to_chain }} := {{ series_to_chain }} * base_series_0)
}
