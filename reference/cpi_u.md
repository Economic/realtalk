# Consumer Price Index for Urban Consumers (CPI-U) data

Monthly, quarterly, or annual CPI-U price indexes

## Usage

``` r
cpi_u_monthly_nsa

cpi_u_monthly_sa

cpi_u_quarterly_nsa

cpi_u_quarterly_sa

cpi_u_annual
```

## Format

The data frames `cpi_u_monthly_sa` and `cpi_u_monthly_nsa` contain,
respectively, seasonally adjusted or not seasonally adjusted monthly
price index levels of the CPI-U. They have three columns:

- year:

  numeric year

- month:

  numeric calendar month (1-12)

- cpi_u:

  value of the CPI-U price index

\#' @format The data frames `cpi_u_quarterly_sa` and
`cpi_u_quarterly_nsa` contain, respectively, seasonally adjusted or not
seasonally adjusted quarterly price index levels of the CPI-U. They have
three columns:

- year:

  numeric year

- quarter:

  numeric calendar quarter (1-4)

- cpi_u:

  value of the CPI-U price index

The data frame `cpi_u_annual` contains the annual price index level of
the CPI-U. It has two columns:

- year:

  numeric year

- cpi_u:

  value of the CPI-U price index

## Source

<https://www.bls.gov/cpi/>

## See also

[`cpi_u_rs_monthly_nsa`](https://economic.github.io/realtalk/reference/cpi_u_rs.md)
and
[`cpi_u_rs_annual`](https://economic.github.io/realtalk/reference/cpi_u_rs.md)
for the CPI-U-RS, an index that is more consistent over time than the
CPI-U and incorporates more recent improvements to the CPI-U into the
entire time series. The quarterly `cpi_u_quarterly_nsa` and
`cpi_u_quarterly_sa` series are the quarterly means of their respective
monthly series.

## Examples

``` r
cpi_u_monthly_nsa
#> # A tibble: 1,071 × 3
#>     year month cpi_u
#>    <dbl> <dbl> <dbl>
#>  1  1937     1  14.1
#>  2  1937     2  14.1
#>  3  1937     3  14.2
#>  4  1937     4  14.3
#>  5  1937     5  14.4
#>  6  1937     6  14.4
#>  7  1937     7  14.5
#>  8  1937     8  14.5
#>  9  1937     9  14.6
#> 10  1937    10  14.6
#> # ℹ 1,061 more rows
```
