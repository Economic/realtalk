# Get price index series as a data frame

Get price index series as a data frame

## Usage

``` r
get_price_index(index_name, frequency, seasonal = NA)
```

## Arguments

- index_name:

  Name of the price index, as specified by index name in
  [`available_price_indexes`](https://economic.github.io/realtalk/reference/available_price_indexes.md)

- frequency:

  "monthly" or "annual"

- seasonal:

  "NSA" or "SA" for monthly data; NA (default) for annual

## Value

A tibble with the requested price index

## Examples

``` r
get_price_index("CPI-U-RS", "monthly", "NSA")
#> # A tibble: 576 × 3
#>     year month cpi_u_rs
#>    <int> <dbl>    <dbl>
#>  1  1977    12     100 
#>  2  1978     1     100.
#>  3  1978     2     101.
#>  4  1978     3     102.
#>  5  1978     4     103.
#>  6  1978     5     104.
#>  7  1978     6     104.
#>  8  1978     7     105 
#>  9  1978     8     106.
#> 10  1978     9     106.
#> # ℹ 566 more rows
```
