#' Chained Consumer Price Index for Urban Consumers (C-CPI-U) data
#'
#' Monthly, quarterly, or annual C-CPI-U price indexes
#'
#' @docType data
#' @name c_cpi_u
#' @keywords datasets
#'
#' @format The data frame `c_cpi_u_monthly_nsa`
#' contains not-seasonally adjusted monthly price index levels of the
#' Chained CPI-U (C-CPI-U). It has three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{month}{numeric calendar month (1-12)}
#'   \item{c_cpi_u}{value of the C-CPI-U price index}
#' }
#'
#'#' @format The data frame `c_cpi_u_quarterly_nsa`
#' contains not-seasonally adjusted quarterly price index levels of the
#' Chained CPI-U (C-CPI-U). It has three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{quarter}{numeric calendar quarter (1-4)}
#'   \item{c_cpi_u}{value of the C-CPI-U price index}
#' }
#'
#' The data frame `c_cpi_u_annual` contains the annual
#' price index level of the Chained CPI-U (C-CPI-U). It has two columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{c_cpi_u}{value of the C-CPI-U price index}
#' }
#'
#' @source The monthly series `cpi_u_monthly_nsa` is taken from
#' <https://www.bls.gov/cpi/>.
#' The quarterly series `cpi_u_quarterly_nsa` series is the quarterly mean.
#'
#' @seealso [`cpi_u_rs_monthly_nsa`][cpi_u_rs] and [`cpi_u_rs_annual`][cpi_u_rs]
#' for the CPI-U-RS, a CPI index that is consistently defined over time and goes
#' back to 1978.
#' @examples
#' c_cpi_u_monthly_nsa

#' @rdname c_cpi_u
#' @format NULL
"c_cpi_u_monthly_nsa"

#' @rdname c_cpi_u
#' @format NULL
"c_cpi_u_quarterly_nsa"

#' @rdname c_cpi_u
#' @format NULL
"c_cpi_u_annual"


