#' Price indexes available in the `realtalk` package
#'
#' @docType data
#' @name available_price_indexes
#' @keywords datasets
#'
#' @format The data frame `available_price_indexes` shows which datasets are
#' available from the `realtalk package`. It has six columns:
#' \describe{
#'   \item{data_source}{Short price index name}
#'   \item{frequency}{time frequency of data available)}
#'   \item{seasonal}{seasonally adjustment status of the data}
#'   \item{min_date}{first date of availability}
#'   \item{max_date}{last date of availability}
#'   \item{package_data_name}{internal data name of the series}
#' }
#'
#' Use the `package_data_name` value to load a specific series.
#'
#' @examples
#' available_price_indexes
"available_price_indexes"


