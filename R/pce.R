#' Personal Consumption Expenditures (PCE) price index
#'
#' Monthly or annual PCE price indexes
#'
#' @docType data
#' @name pce
#' @keywords datasets
#'
#' @format The data frame `pce_monthly_sa` contains seasonally adjusted
#' price index levels of the PCE. It has three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{month}{numeric calendar month (1-12)}
#'   \item{pce}{value of the PCE price index}
#' }
#'
#' The data frame `pce_annual` contains the annual
#' price index level of the PCE. It has two columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{pce}{value of the PCE price index}
#' }
#'
#' @source <https://www.bea.gov/data/personal-consumption-expenditures-price-index>
#' @examples
#' pce_annual

#' @rdname pce
#' @format NULL
"pce_monthly_sa"

#' @rdname pce
#' @format NULL
"pce_annual"


