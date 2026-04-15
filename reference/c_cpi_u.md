# Chained Consumer Price Index for Urban Consumers (C-CPI-U) data

Monthly, quarterly, or annual C-CPI-U price indexes

## Usage

``` r
c_cpi_u_monthly_nsa

c_cpi_u_quarterly_nsa

c_cpi_u_annual
```

## Format

The data frame `c_cpi_u_monthly_nsa` contains not-seasonally adjusted
monthly price index levels of the Chained CPI-U (C-CPI-U). It has three
columns:

- year:

  numeric year

- month:

  numeric calendar month (1-12)

- c_cpi_u:

  value of the C-CPI-U price index

The data frame `c_cpi_u_quarterly_nsa` contains not-seasonally adjusted
quarterly price index levels of the Chained CPI-U (C-CPI-U). It has
three columns:

- year:

  numeric year

- quarter:

  numeric calendar quarter (1-4)

- c_cpi_u:

  value of the C-CPI-U price index

The data frame `c_cpi_u_annual` contains the annual price index level of
the Chained CPI-U (C-CPI-U). It has two columns:

- year:

  numeric year

- c_cpi_u:

  value of the C-CPI-U price index

## Source

The monthly series `cpi_u_monthly_nsa` is taken from
<https://www.bls.gov/cpi/>. The quarterly series `cpi_u_quarterly_nsa`
series is the quarterly mean.

## See also

[`cpi_u_rs_monthly_nsa`](https://economic.github.io/realtalk/reference/cpi_u_rs.md)
and
[`cpi_u_rs_annual`](https://economic.github.io/realtalk/reference/cpi_u_rs.md)
for the CPI-U-RS, a CPI index that is consistently defined over time and
goes back to 1978.

## Examples

``` r
c_cpi_u_monthly_nsa
#> # A tibble: 316 × 3
#>     year month c_cpi_u
#>    <dbl> <dbl>   <dbl>
#>  1  1999    12    100 
#>  2  2000     1    100.
#>  3  2000     2    101.
#>  4  2000     3    102.
#>  5  2000     4    102.
#>  6  2000     5    102.
#>  7  2000     6    102.
#>  8  2000     7    102.
#>  9  2000     8    102.
#> 10  2000     9    103.
#> # ℹ 306 more rows
```
