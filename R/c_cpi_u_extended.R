#' Extended Chained Chained Consumer Price Index for Urban Consumers (C-CPI-U)
#'
#' The monthly or annual C-CPI-U series extended to 1937 through
#' the present, based on CPI-U-RS, CPI-U, and CPI-U-X1.
#'
#' @docType data
#' @name c_cpi_u_extended
#' @keywords datasets
#'
#' @format The extended C-CPI-U series uses the 1978-2000 CPI-U-RS
#' and extends it retroactively by chaining it to the
#' CPI-U-RS (1978-1999), CPI-U-X1 (1967-1977),
#' and CPI-U (1966 and before).
#'
#' The data frames `c_cpi_u_extended_monthly_nsa` and
#' `c_cpi_u_extended_monthly_sa` contain, respectively, the
#' not-seasonally and seasonally adjusted price index levels of the
#' extended C-CPI-U. They have three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{month}{numeric calendar month (1-12)}
#'   \item{pce}{value of the C-CPI-U extended price index}
#' }
#'
#' The data frame `c_cpi_u_extended annual` contains the annual
#' price index level of the extended C-CPI-U. It has two columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{pce}{value of the C-CPI-U extended price index}
#' }
#'
#' @source The seasonal adjustment in `cpi_u_rs_extended_monthly_sa` is simply
#' a multiplication of the non-seasonally adjusted
#' `cpi_u_rs_extended_monthly_nsa` values by the ratio of the
#' [`cpi_u_monthly_sa`][cpi_u] to [`cpi_u_monthly_nsa`][cpi_u].
#'
#' For annual statistics, the U.S. Census Bureau currently uses a similar
#' combination of price indexes to extend the CPI-U-RS and CPI-U:
#' <https://www.census.gov/topics/income-poverty/income/guidance/current-vs-constant-dollars.html>.
#' @examples
#' c_cpi_u_extended_annual

#' @rdname c_cpi_u_extended
#' @format NULL
"c_cpi_u_extended_monthly_nsa"

#' @rdname c_cpi_u_extended
#' @format NULL
"c_cpi_u_extended_monthly_sa"

#' @rdname c_cpi_u_extended
#' @format NULL
"c_cpi_u_extended_annual"

