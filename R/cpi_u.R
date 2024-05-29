#' Consumer Price Index for Urban Consumers (CPI-U) data
#'
#' Monthly, quarterly, or annual CPI-U price indexes
#'
#' @docType data
#' @name cpi_u
#' @keywords datasets
#'
#' @format The data frames `cpi_u_monthly_sa` and `cpi_u_monthly_nsa`
#' contain, respectively, seasonally adjusted or not seasonally adjusted monthly
#' price index levels of the CPI-U. They have three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{month}{numeric calendar month (1-12)}
#'   \item{cpi_u}{value of the CPI-U price index}
#' }
#'
#' #' @format The data frames `cpi_u_quarterly_sa` and `cpi_u_quarterly_nsa`
#' contain, respectively, seasonally adjusted or not seasonally adjusted quarterly
#' price index levels of the CPI-U. They have three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{quarter}{numeric calendar quarter (1-4)}
#'   \item{cpi_u}{value of the CPI-U price index}
#' }
#'
#' The data frame `cpi_u_annual` contains the annual
#' price index level of the CPI-U. It has two columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{cpi_u}{value of the CPI-U price index}
#' }
#'
#' @source <https://www.bls.gov/cpi/>
#' @seealso [`cpi_u_rs_monthly_nsa`][cpi_u_rs] and [`cpi_u_rs_annual`][cpi_u_rs]
#' for the CPI-U-RS, an index that is more consistent over time than the CPI-U
#' and incorporates more recent improvements to the CPI-U into the
#' entire time series. The quarterly `cpi_u_quarterly_nsa` and
#' `cpi_u_quarterly_sa` series are the quarterly means of their
#' respective monthly series.
#'
#' @examples
#' cpi_u_monthly_nsa

#' @rdname cpi_u
#' @format NULL
"cpi_u_monthly_nsa"

#' @rdname cpi_u
#' @format NULL
"cpi_u_monthly_sa"

#' @rdname cpi_u
#' @format NULL
"cpi_u_quarterly_nsa"

#' @rdname cpi_u
#' @format NULL
"cpi_u_quarterly_sa"

#' @rdname cpi_u
#' @format NULL
"cpi_u_annual"


