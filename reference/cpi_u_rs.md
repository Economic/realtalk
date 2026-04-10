# Consumer Price Index for Urban Consumers Research Series (CPI-U-RS) data

Monthly or annual CPI-U-RS price indexes

## Usage

``` r
cpi_u_rs_monthly_nsa

cpi_u_rs_annual
```

## Format

The data frame `cpi_u_rs_monthly_nsa` contains the not seasonally
adjusted monthly price index levels of the CPI-U-RS (CPI-U research
series). The CPI-U-RS is more consistent over time than the CPI-U and
incorporates more recent improvements to the CPI-U into the entire time
series. It has three columns:

- year:

  numeric year

- month:

  numeric calendar month (1-12)

- cpi_u_rs:

  value of the CPI-U-RS price index

The data frame `cpi_u_rs_annual` contains the annual price index level
of the CPI-U-RS. It has two columns:

- year:

  numeric year

- cpi_u_rs:

  value of the CPI-U-RS price index

## Source

<https://www.bls.gov/cpi/research-series/r-cpi-u-rs-home.htm>

## See also

[`c_cpi_u_extended_annual`](https://economic.github.io/realtalk/reference/c_cpi_u_extended.md)
extends the CPI-U-RS from 1937 to the present using the
[`c_cpi_u`](https://economic.github.io/realtalk/reference/c_cpi_u.md)
and other series.

## Examples

``` r
cpi_u_rs_annual
#> # A tibble: 48 × 2
#>     year cpi_u_rs
#>    <dbl>    <dbl>
#>  1  1978     104.
#>  2  1979     114.
#>  3  1980     127.
#>  4  1981     139.
#>  5  1982     148.
#>  6  1983     154.
#>  7  1984     160.
#>  8  1985     166.
#>  9  1986     168.
#> 10  1987     174.
#> # ℹ 38 more rows
```
