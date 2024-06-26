#' Consumer Price Index for Urban Consumers Research Series (CPI-U-RS) data
#'
#' Monthly or annual CPI-U-RS price indexes
#'
#' @docType data
#' @name cpi_u_rs
#' @keywords datasets
#'
#' @format The data frame `cpi_u_rs_monthly_nsa` contains the
#' not seasonally adjusted monthly price index levels of the CPI-U-RS
#' (CPI-U research series). The CPI-U-RS is more consistent over time than
#' the CPI-U and incorporates more recent improvements to the CPI-U into the
#' entire time series. It has three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{month}{numeric calendar month (1-12)}
#'   \item{cpi_u_rs}{value of the CPI-U-RS price index}
#' }
#'
#' The data frame `cpi_u_rs_annual` contains the annual
#' price index level of the CPI-U-RS. It has two columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{cpi_u_rs}{value of the CPI-U-RS price index}
#' }
#'
#' @source <https://www.bls.gov/cpi/research-series/r-cpi-u-rs-home.htm>
#' @seealso [`c_cpi_u_extended_annual`][`c_cpi_u_extended`] extends the
#' CPI-U-RS from 1937 to the present using the [`c_cpi_u`] and other series.
#'
#' @examples
#' cpi_u_rs_annual

#' @rdname cpi_u_rs
#' @format NULL
"cpi_u_rs_monthly_nsa"

#' @rdname cpi_u_rs
#' @format NULL
"cpi_u_rs_annual"


