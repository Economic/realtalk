# Experimental Consumer Price Index for Urban Consumers X1 (CPI-U-X1) data

Monthly or annual CPI-U-X1 price indexes

## Usage

``` r
cpi_u_x1_monthly_nsa

cpi_u_x1_annual
```

## Format

The data frame `cpi_u_x1_monthly_nsa` contains the not seasonally
adjusted monthly price index levels of the CPI-U-X1 from January 1967
through December 1982. It has three columns:

- year:

  numeric year

- month:

  numeric calendar month (1-12)

- cpi_u_x1:

  value of the CPI-U-X1 price index

The data frame `cpi_u_x1_annual` contains the annual average price index
level of the CPI-U-X1. It has two columns:

- year:

  numeric year

- cpi_u_x1:

  value of the CPI-U-X1 price index

## Source

Emailed spreadsheet from the US Bureau of Labor Statistics

## See also

[`c_cpi_u_extended_annual`](https://economic.github.io/realtalk/reference/c_cpi_u_extended.md)
extends the CPI-U-X1 from 1937 to the present using the
[`c_cpi_u`](https://economic.github.io/realtalk/reference/c_cpi_u.md)
and other series.

## Examples

``` r
cpi_u_x1_annual
#> # A tibble: 16 × 2
#>     year cpi_u_x1
#>    <dbl>    <dbl>
#>  1  1967     36.4
#>  2  1968     37.7
#>  3  1969     39.4
#>  4  1970     41.3
#>  5  1971     43.1
#>  6  1972     44.4
#>  7  1973     47.2
#>  8  1974     51.9
#>  9  1975     56.2
#> 10  1976     59.4
#> 11  1977     63.2
#> 12  1978     67.5
#> 13  1979     74  
#> 14  1980     82.3
#> 15  1981     90.1
#> 16  1982     95.6
```
