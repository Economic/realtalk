# Extended Chained Consumer Price Index for Urban Consumers (C-CPI-U)

The monthly, quarterly, or annual C-CPI-U series extended to 1937
through the present, based on CPI-U-RS, CPI-U, and CPI-U-X1.

## Usage

``` r
c_cpi_u_extended_monthly_nsa

c_cpi_u_extended_monthly_sa

c_cpi_u_extended_quarterly_nsa

c_cpi_u_extended_quarterly_sa

c_cpi_u_extended_annual
```

## Format

The extended C-CPI-U series uses the C-CPI-U since 2000 and extends it
retroactively by merging it to the CPI-U-RS (1978-1999), CPI-U-X1
(1967-1977), and CPI-U (1966 and before).

The data frames `c_cpi_u_extended_monthly_nsa` and
`c_cpi_u_extended_monthly_sa` contain, respectively, the not-seasonally
and seasonally adjusted price index levels of the extended C-CPI-U. They
have three columns:

- year:

  numeric year

- month:

  numeric calendar month (1-12)

- c_cpi_u_extended:

  value of the C-CPI-U extended price index

The data frames `c_cpi_u_extended_quarterly_nsa` and
`c_cpi_u_extended_quarterly_sa` are the quarterly versions of these
series. They have three columns:

- year:

  numeric year

- quarter:

  numeric calendar quarter (1-4)

- c_cpi_u_extended:

  value of the C-CPI-U extended price index

The data frame `c_cpi_u_extended annual` contains the annual price index
level of the extended C-CPI-U. It has two columns:

- year:

  numeric year

- c_cpi_u_extended:

  value of the C-CPI-U extended price index

## Source

The seasonal adjustment in `c_cpi_u_extended_monthly_sa` is simply a
multiplication of the non-seasonally adjusted
`c_cpi_u_extended_monthly_nsa` values by the ratio of the
[`cpi_u_monthly_sa`](https://economic.github.io/realtalk/reference/cpi_u.md)
to
[`cpi_u_monthly_nsa`](https://economic.github.io/realtalk/reference/cpi_u.md).
The quarterly `c_cpi_u_extended_quarterly_nsa` and
`c_cpi_u_extended_quarterly_sa` series are the quarterly means of their
respective monthly series.

For months where CPI data was not published (e.g., October 2025), the
monthly extended series values are linearly interpolated from the
adjacent months' values. The quarterly series are then computed as usual
from the monthly values including any interpolated months.

For annual statistics, the U.S. Census Bureau currently uses a similar
combination of price indexes to extend the C-CPI-U:
<https://www.census.gov/topics/income-poverty/income/guidance/current-vs-constant-dollars.html>.

## Examples

``` r
c_cpi_u_extended_annual
#> # A tibble: 89 × 2
#>     year c_cpi_u_extended
#>    <dbl>            <dbl>
#>  1  1937              9.8
#>  2  1938              9.6
#>  3  1939              9.5
#>  4  1940              9.5
#>  5  1941             10  
#>  6  1942             11.1
#>  7  1943             11.8
#>  8  1944             12  
#>  9  1945             12.3
#> 10  1946             13.3
#> # ℹ 79 more rows
```
