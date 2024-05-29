catalog_data <- function(...) {
  args <- ensyms(...)
  available_price_indexes <- map_chr(args, rlang::as_string) %>%
    map(summarize_datasets) %>%
    list_rbind %>%
    arrange(index_name, frequency, seasonal)

  ### OUTPUT
  available_csv <- "data-raw/processed/available_price_indexes.csv"
  available_rda <- "data/available_price_indexes.rda"

  available_price_indexes %>%
    write_csv(available_csv)

  usethis::use_data(available_price_indexes, overwrite = TRUE)

  output <- c(available_csv, available_rda)
  output

}

summarize_datasets <- function(x) {
  tar_read_raw(x) %>%
    str_subset(".rda") %>%
    map(single_dataset_info) %>%
    list_rbind
}

single_dataset_info <- function(x) {
  file <- load(x)
  data <- get(file)

  index_name <- file %>%
    str_replace("_monthly.*", "") %>%
    str_replace("_annual.*", "") %>%
    str_replace("_quarterly.*", "") %>%
    str_replace_all("_", "-") %>%
    str_to_upper() %>%
    str_replace("-EXTENDED", ", extended")

  monthly <- str_extract(file, "monthly")
  quarterly <- str_extract(file, "quarterly")
  annual <- str_extract(file, "annual")
  frequency <- ifelse(is.na(monthly), annual, monthly)
  frequency <- ifelse(is.na(frequency), quarterly, frequency)

  seasonal <- str_extract(file, "_nsa|_sa") %>%
    str_replace("_", "") %>%
    str_to_upper()

  if (frequency == "monthly") {
    dates <- data %>%
      mutate(date = ym(paste(year, month))) %>%
      summarize(min_date = min(date), max_date = max(date)) %>%
      mutate(across(everything(), ~ format(.x, "%b %Y")))
  }

  if (frequency == "quarterly") {
    dates <- data %>%
      mutate(date = yq(paste(year, quarter))) %>%
      summarize(min_date = min(date), max_date = max(date)) %>%
      mutate(across(everything(), ~ paste0(year(.x), "q", quarter(.x))))
  }

  if (frequency == "annual") {
    dates <- data %>%
      summarize(min_date = min(year), max_date = max(year)) %>%
      mutate(across(everything(), as.character))
  }

  min_date <- dates %>%
    pull(min_date)

  max_date <- dates %>%
    pull(max_date)

  documented_data <- tribble(
    ~index_name, ~frequency, ~seasonal, ~min_date, ~max_date, ~package_data_name,
    index_name, frequency, seasonal, min_date, max_date, file
  )

  documented_data

}

