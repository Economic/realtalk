# Example nominal US federal minimum wage data

Example nominal US federal minimum wage data

## Usage

``` r
us_minimum_wage_monthly

us_minimum_wage_annual
```

## Format

The data frame `us_minimum_wage_annual` contains the nominal value of
the annual US federal minimum wage since 1938. It has two columns:

- year:

  numeric year

- minimum_wage:

  maximum value of the US federal minimum wage that year

The data frame `us_minimum_wage_monthly` contains the nominal value of
the monthly US federal minimum wage since 1938. It has three columns:

- year:

  numeric year

- year:

  numeric month

- minimum_wage:

  maximum value of the US federal minimum wage that month

## Source

[US Department of
Labor](https://www.dol.gov/agencies/whd/minimum-wage/history/chart)

## Examples

``` r
us_minimum_wage_monthly
#> # A tibble: 1,049 × 3
#>     year month minimum_wage
#>    <dbl> <dbl>        <dbl>
#>  1  1938    10         0.25
#>  2  1938    11         0.25
#>  3  1938    12         0.25
#>  4  1939     1         0.25
#>  5  1939     2         0.25
#>  6  1939     3         0.25
#>  7  1939     4         0.25
#>  8  1939     5         0.25
#>  9  1939     6         0.25
#> 10  1939     7         0.25
#> # ℹ 1,039 more rows
```
