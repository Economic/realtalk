#' Get price index series as a data frame
#'
#' @param index_name Name of the price index, as specified by index name in [`available_price_indexes`]
#' @param frequency "monthly" or "annual"
#' @param seasonal "NSA" or "SA" for monthly data; NA (default) for annual
#'
#' @return A tibble with the requested price index
#' @export
#'
#' @examples
#' get_price_index("CPI-U-RS", "monthly", "NSA")
get_price_index <- function(index_name, frequency, seasonal = NA) {
  index_name <- tolower(index_name)
  index_name <- gsub("[[:punct:]]", "", index_name)
  index_name <- gsub(" ", "", index_name)

  if (!is.na(seasonal)) {
    seasonal <- tolower(seasonal)
  }

  if (is.na(seasonal)) {
    valid_name <- paste0(index_name, frequency)
  }
  else {
    valid_name <- paste0(index_name, frequency, seasonal)
  }

  main_list <- realtalk::available_price_indexes

  available <- subset(
    main_list,
    valid_name == gsub("[[:punct:]]", "", main_list$package_data_name)
  )

  if (nrow(available) != 1) {
    stop(
      "Specified index_name in get_price_index() does not uniquely match entry in available_price_indexes"
    )
  }
  else {
    get(available[["package_data_name"]])
  }
}

price_inflate_annual <- function(variable, index, year_base) {

}

price_inflate_monthly <- function(variable, index, year_base, month_base, seasonal) {

}
