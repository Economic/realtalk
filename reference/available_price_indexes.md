# Price indexes available in the `realtalk` package

Price indexes available in the `realtalk` package

## Usage

``` r
available_price_indexes
```

## Format

The data frame `available_price_indexes` shows which datasets are
available from the `realtalk package`. It has six columns:

- data_source:

  Short price index name

- frequency:

  time frequency of data available)

- seasonal:

  seasonally adjustment status of the data

- min_date:

  first date of availability

- max_date:

  last date of availability

- package_data_name:

  internal data name of the series

Use the `package_data_name` value to load a specific series.

## Examples

``` r
available_price_indexes
#> # A tibble: 20 × 6
#>    index_name        frequency seasonal min_date max_date package_data_name     
#>    <chr>             <chr>     <chr>    <chr>    <chr>    <chr>                 
#>  1 C-CPI-U           annual    NA       2000     2025     c_cpi_u_annual        
#>  2 C-CPI-U           monthly   NSA      Dec 1999 Feb 2026 c_cpi_u_monthly_nsa   
#>  3 C-CPI-U           quarterly NSA      2000q1   2025q4   c_cpi_u_quarterly_nsa 
#>  4 C-CPI-U, extended annual    NA       1937     2025     c_cpi_u_extended_annu…
#>  5 C-CPI-U, extended monthly   NSA      Jan 1937 Feb 2026 c_cpi_u_extended_mont…
#>  6 C-CPI-U, extended monthly   SA       Jan 1947 Feb 2026 c_cpi_u_extended_mont…
#>  7 C-CPI-U, extended quarterly NSA      1937q1   2025q4   c_cpi_u_extended_quar…
#>  8 C-CPI-U, extended quarterly SA       1947q1   2025q4   c_cpi_u_extended_quar…
#>  9 CPI-U             annual    NA       1937     2025     cpi_u_annual          
#> 10 CPI-U             monthly   NSA      Jan 1937 Feb 2026 cpi_u_monthly_nsa     
#> 11 CPI-U             monthly   SA       Jan 1947 Feb 2026 cpi_u_monthly_sa      
#> 12 CPI-U             quarterly NSA      1937q1   2025q4   cpi_u_quarterly_nsa   
#> 13 CPI-U             quarterly SA       1947q1   2025q4   cpi_u_quarterly_sa    
#> 14 CPI-U-RS          annual    NA       1978     2024     cpi_u_rs_annual       
#> 15 CPI-U-RS          monthly   NSA      Dec 1977 Dec 2024 cpi_u_rs_monthly_nsa  
#> 16 CPI-U-X1          annual    NA       1967     1982     cpi_u_x1_annual       
#> 17 CPI-U-X1          monthly   NSA      Jan 1967 Dec 1982 cpi_u_x1_monthly_nsa  
#> 18 PCE               annual    NA       1929     2025     pce_annual            
#> 19 PCE               monthly   SA       Jan 1959 Dec 2025 pce_monthly_sa        
#> 20 PCE               quarterly SA       1947q1   2025q4   pce_quarterly_sa      
```
