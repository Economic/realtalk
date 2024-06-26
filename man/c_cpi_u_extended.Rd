% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/c_cpi_u_extended.R
\docType{data}
\name{c_cpi_u_extended}
\alias{c_cpi_u_extended}
\alias{c_cpi_u_extended_monthly_nsa}
\alias{c_cpi_u_extended_monthly_sa}
\alias{c_cpi_u_extended_quarterly_nsa}
\alias{c_cpi_u_extended_quarterly_sa}
\alias{c_cpi_u_extended_annual}
\title{Extended Chained Consumer Price Index for Urban Consumers (C-CPI-U)}
\format{
The extended C-CPI-U series uses the C-CPI-U since 2000
and extends it retroactively by merging it to the
CPI-U-RS (1978-1999), CPI-U-X1 (1967-1977),
and CPI-U (1966 and before).

The data frames \code{c_cpi_u_extended_monthly_nsa} and
\code{c_cpi_u_extended_monthly_sa} contain, respectively, the
not-seasonally and seasonally adjusted price index levels of the
extended C-CPI-U. They have three columns:
\describe{
\item{year}{numeric year}
\item{month}{numeric calendar month (1-12)}
\item{c_cpi_u_extended}{value of the C-CPI-U extended price index}
}

The data frames \code{c_cpi_u_extended_quarterly_nsa} and
\code{c_cpi_u_extended_quarterly_sa} are the quarterly versions of these
series. They have three columns:
\describe{
\item{year}{numeric year}
\item{quarter}{numeric calendar quarter (1-4)}
\item{c_cpi_u_extended}{value of the C-CPI-U extended price index}
}

The data frame \verb{c_cpi_u_extended annual} contains the annual
price index level of the extended C-CPI-U. It has two columns:
\describe{
\item{year}{numeric year}
\item{c_cpi_u_extended}{value of the C-CPI-U extended price index}
}
}
\source{
The seasonal adjustment in \code{c_cpi_u_extended_monthly_sa} is simply
a multiplication of the non-seasonally adjusted
\code{c_cpi_u_extended_monthly_nsa} values by the ratio of the
\code{\link[=cpi_u]{cpi_u_monthly_sa}} to \code{\link[=cpi_u]{cpi_u_monthly_nsa}}.
The quarterly \code{c_cpi_u_extended_quarterly_nsa} and \code{c_cpi_u_extended_quarterly_sa}
series are the quarterly means of their respective monthly series.

For annual statistics, the U.S. Census Bureau currently uses a similar
combination of price indexes to extend the C-CPI-U:
\url{https://www.census.gov/topics/income-poverty/income/guidance/current-vs-constant-dollars.html}.
}
\usage{
c_cpi_u_extended_monthly_nsa

c_cpi_u_extended_monthly_sa

c_cpi_u_extended_quarterly_nsa

c_cpi_u_extended_quarterly_sa

c_cpi_u_extended_annual
}
\description{
The monthly, quarterly, or annual C-CPI-U series extended to 1937 through
the present, based on CPI-U-RS, CPI-U, and CPI-U-X1.
}
\examples{
c_cpi_u_extended_annual
}
\keyword{datasets}
