#' Consumer Price Index for Urban Consumers (CPI-U) data
#'
#' Excerpt of the Gapminder data on life expectancy, GDP per capita, and
#' population by country.
#'
#' @format The main data frame `gapminder` has 1704 rows and 6 variables:
#' \describe{
#'   \item{country}{factor with 142 levels}
#'   \item{continent}{factor with 5 levels}
#'   \item{year}{ranges from 1952 to 2007 in increments of 5 years}
#'   \item{lifeExp}{life expectancy at birth, in years}
#'   \item{pop}{population}
#'   \item{gdpPercap}{GDP per capita (US$, inflation-adjusted)}
#'   }
#'
#' The supplemental data frame [`gapminder_unfiltered`] was not
#' filtered on `year` or for complete data and has 3313 rows.
#'
#' @source <https://www.bls.gov/cpi/>
#' @seealso [`country_colors`] for a nice color scheme for the countries
#' @importFrom tibble tibble
#' @examples
#' str(cpi_u_monthly_nsa)
#'
"cpi_u_monthly_nsa"

#' @rdname cpi_u_monthly_nsa
"cpi_u_monthly_sa"