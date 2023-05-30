
<!-- README.md is generated from README.Rmd. Please edit that file -->

# realtalk <a href="https://economic.github.io/realtalk/"><img src="man/figures/logo.png" align="right" width="120" /></a>

<!-- badges: start -->
<!-- badges: end -->

realtalk makes it easy to use common US price indexes in your data
analysis.

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" />

## Loading the data

`realtalk` is mostly a data package and includes several datasets of
common US price indexes, like the CPI-U-RS

``` r
library(realtalk)
cpi_u_rs_annual
#> # A tibble: 45 × 2
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
#> # ℹ 35 more rows
```

You can see what datasets are available by loading
`available_price_indexes`:

``` r
available_price_indexes
#> # A tibble: 11 × 6
#>    data_source       frequency seasonal min_date max_date package_data_name     
#>    <chr>             <chr>     <chr>    <chr>    <chr>    <chr>                 
#>  1 cpi_u             monthly   NSA      Jan 1937 Apr 2023 cpi_u_monthly_nsa     
#>  2 cpi_u             monthly   SA       Jan 1947 Apr 2023 cpi_u_monthly_sa      
#>  3 cpi_u             annual    <NA>     1937     2023     cpi_u_annual          
#>  4 cpi_u_x1          monthly   NSA      Jan 1967 Dec 1982 cpi_u_x1_monthly_nsa  
#>  5 cpi_u_x1          annual    <NA>     1967     1982     cpi_u_x1_annual       
#>  6 cpi_u_rs          monthly   NSA      Dec 1977 Dec 2022 cpi_u_rs_monthly_nsa  
#>  7 cpi_u_rs          annual    <NA>     1978     2022     cpi_u_rs_annual       
#>  8 cpi_u_rs_extended monthly   NSA      Jan 1937 Apr 2023 cpi_u_rs_extended_mon…
#>  9 cpi_u_rs_extended annual    <NA>     1937     2022     cpi_u_rs_extended_ann…
#> 10 pce               monthly   SA       Jan 1959 Apr 2023 pce_monthly_sa        
#> 11 pce               annual    <NA>     1929     2022     pce_annual
```

The `package_data_name` column contains the internal name of each
dataset:

``` r
pce_monthly_sa
#> # A tibble: 772 × 3
#>     year month   pce
#>    <dbl> <dbl> <dbl>
#>  1  1959     1  16.0
#>  2  1959     2  16.1
#>  3  1959     3  16.1
#>  4  1959     4  16.1
#>  5  1959     5  16.1
#>  6  1959     6  16.2
#>  7  1959     7  16.2
#>  8  1959     8  16.2
#>  9  1959     9  16.3
#> 10  1959    10  16.3
#> # ℹ 762 more rows
```

## Installation

``` r
# install.packages("devtools")
devtools::install_github("Economic/realtalk")
```
