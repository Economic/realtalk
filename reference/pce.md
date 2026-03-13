# Personal Consumption Expenditures (PCE) price index

Monthly, quarterly, or annual PCE price indexes

## Usage

``` r
pce_monthly_sa

pce_quarterly_sa

pce_annual
```

## Format

The data frame `pce_monthly_sa` contains seasonally adjusted monthly
price index levels of the PCE. It has three columns:

- year:

  numeric year

- month:

  numeric calendar month (1-12)

- pce:

  value of the PCE price index

The data frame `pce_quarterly_sa` contains seasonally adjusted quarterly
price index levels of the PCE. It has three columns:

- year:

  numeric year

- quarter:

  numeric calendar quarter (1-3)

- pce:

  value of the PCE price index

The data frame `pce_annual` contains the annual price index level of the
PCE. It has two columns:

- year:

  numeric year

- pce:

  value of the PCE price index

## Source

<https://www.bea.gov/data/personal-consumption-expenditures-price-index>

## Examples

``` r
pce_annual
#> # A tibble: 97 × 2
#>     year   pce
#>    <dbl> <dbl>
#>  1  1929  8.79
#>  2  1930  8.41
#>  3  1931  7.51
#>  4  1932  6.63
#>  5  1933  6.39
#>  6  1934  6.68
#>  7  1935  6.85
#>  8  1936  6.91
#>  9  1937  7.16
#> 10  1938  7.00
#> # ℹ 87 more rows
```
