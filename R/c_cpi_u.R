#' Chained Consumer Price Index for Urban Consumers (C-CPI-U) data
#'
#' Monthly or annual C-CPI-U price indexes
#'
#' @docType data
#' @name c_cpi_u
#' @keywords datasets
#'
#' @format The data frame `c_cpi_u_monthly_nsa`
#' contains not-seasonally adjusted price index levels of the
#' Chained CPI-U (C-CPI-U). It has three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{month}{numeric calendar month (1-12)}
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
#' @source <https://www.bls.gov/cpi/>
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
"c_cpi_u_annual"


