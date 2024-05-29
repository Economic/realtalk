#' Experimental Consumer Price Index for Urban Consumers X1 (CPI-U-X1) data
#'
#' Monthly or annual CPI-U-X1 price indexes
#'
#' @docType data
#' @name cpi_u_x1
#' @keywords datasets
#'
#' @format The data frame `cpi_u_x1_monthly_nsa` contains the
#' not seasonally adjusted monthly price index levels of the CPI-U-X1
#' from January 1967 through December 1982. It has three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{month}{numeric calendar month (1-12)}
#'   \item{cpi_u_x1}{value of the CPI-U-X1 price index}
#' }
#'
#' The data frame `cpi_u_x1_annual` contains the annual average
#' price index level of the CPI-U-X1. It has two columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{cpi_u_x1}{value of the CPI-U-X1 price index}
#' }
#'
#' @source Emailed spreadsheet from the US Bureau of Labor Statistics
#' @seealso [`c_cpi_u_extended_annual`][`c_cpi_u_extended`] extends the
#' CPI-U-X1 from 1937 to the present using the [`c_cpi_u`] and other series.
#' @examples
#' cpi_u_x1_annual

#' @rdname cpi_u_x1
#' @format NULL
"cpi_u_x1_monthly_nsa"

#' @rdname cpi_u_x1
#' @format NULL
"cpi_u_x1_annual"


