#' Extended CPI-U-RS price index
#'
#' The monthly or annual CPI-U-RS series extended to 1937 through
#' the present, based on CPI-U-RS, CPI-U, and CPI-U-X1.
#'
#' @docType data
#' @name cpi_u_rs_extended
#' @keywords datasets
#'
#' @format The extended CPI-U-RS series uses the 1978-2022 CPI-U-RS
#' and extends it retroactively by chaining it to the
#' CPI-U-RS (1978-2022), CPI-U-X1 (1967-1977),
#' and CPI-U (1966 and before, and 2023 through the present).
#'
#' The data frames `cpi_u_rs_extended_monthly_nsa` and
#' `cpi_u_rs_extended_monthly_sa` contain, respectively, the not-seasonally
#' and seasonally adjusted price index levels of the extended CPI-U-RS.
#' They have three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{month}{numeric calendar month (1-12)}
#'   \item{pce}{value of the CPI-U-RS extended price index}
#' }
#'
#' The data frame `cpi_u_rs_extended annual` contains the annual
#' price index level of the extended CPI-U-RS. It has two columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{pce}{value of the CPI-U-RS extended price index}
#' }
#'
#' @source The seasonal adjustment in `c_cpi_u_extended_monthly_sa` is simply
#' a multiplication of the non-seasonally adjusted
#' `c_cpi_u_extended_monthly_nsa` values by the ratio of the
#' [`cpi_u_monthly_sa`][cpi_u] to [`cpi_u_monthly_nsa`][cpi_u].
#'
#' For annual statistics, the U.S. Census Bureau previously used a
#' similar combination of price indexes to extend the CPI-U-RS.
#' Now it uses the methodology similar to that described by the extended
#' Chained CPI-U [`c_cpi_u_extended_annual`][c_cpi_u_extended].
#' @examples
#' cpi_u_rs_extended_annual

#' @rdname cpi_u_rs_extended
#' @format NULL
"cpi_u_rs_extended_monthly_nsa"

#' @rdname cpi_u_rs_extended
#' @format NULL
"cpi_u_rs_extended_monthly_sa"

#' @rdname cpi_u_rs_extended
#' @format NULL
"cpi_u_rs_extended_annual"


