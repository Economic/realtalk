#' Example nominal US federal minimum wage data
#'
#' @docType data
#' @name us_minimum_wage
#' @keywords datasets
#'
#' @format The data frame `us_minimum_wage_annual` contains the
#' nominal value of the annual US federal minimum wage since 1938.
#' It has two columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{minimum_wage}{maximum value of the US federal minimum wage that year}
#' }
#'
#' @format The data frame `us_minimum_wage_monthly` contains the
#' nominal value of the monthly US federal minimum wage since 1938.
#' It has three columns:
#' \describe{
#'   \item{year}{numeric year}
#'   \item{year}{numeric month}
#'   \item{minimum_wage}{maximum value of the US federal minimum wage that month}
#' }
#'
#' @source \href{https://www.dol.gov/agencies/whd/minimum-wage/history/chart}{US Department of Labor}
#'
#' @examples
#' us_minimum_wage_monthly

#' @rdname us_minimum_wage
#' @format NULL
"us_minimum_wage_monthly"

#' @rdname us_minimum_wage
#' @format NULL
"us_minimum_wage_annual"
