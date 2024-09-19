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

chain_to_base_annual <- function(data, series_to_chain, base_series, base_year) {
  # root value of new base series
  base_series_0 <- data %>%
    filter(year == base_year) %>%
    pull({{base_series}})

  # root value of old series to be chained
  series_to_chain_0 <- data %>%
    filter(year == base_year) %>%
    pull({{series_to_chain}})

  # chain the series
  data %>%
    mutate({{series_to_chain}} := {{series_to_chain}} / series_to_chain_0) %>%
    mutate({{series_to_chain}} := {{series_to_chain}} * base_series_0)
}
