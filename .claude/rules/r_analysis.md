# Guidance for data analysis in R

## Running and verifying code

Run the scripts that you write or edit and fix any errors.

To run R code, use `Rscript main.R` or `Rscript -e "some_expression"`. For targets workflows, use `Rscript -e 'targets::tar_make()'`.

For multi-file workflows, source a separate `packages.R` file that contains all `library()` calls.

Use `renv` only if explicitly requested or already initialized.

## Writing R code

### General conventions

- Use base pipe `|>` instead of `%>%`
- Use tidyverse-friendly code
- Prefer `readr` or `arrow` packages over `read.csv`
- Prefer `stringr` over base regex functions
- Prefer `forcats` for factor handling
- Make plots using `ggplot2`

**Important**: If a `CLAUDE.md` contains different guidance, follow `CLAUDE.md`. Inform the user if your context contains contradictory instructions.

### Packages
For single-file scripts, load all packages with `library()` calls at the top of the file. For multi-file workflows, these calls go in `packages.R` (see above). 

Load the `conflicted` package near the top to flag function name conflicts across packages. Use `conflicts_prefer` to manage them:

```r
library(conflicted)
library(tidyverse)
conflicts_prefer(dplyr::filter, dplyr::lag)
```

Loading the entire tidyverse is acceptable unless there are concerns about performance or this analysis is part of an R package.

Do not use `package::function()` to call functions as part of an analysis; use `library()` calls as described above.

### File names

Use lower case for file names. Delimit words with `_` or `-`; prefer `_`, but if existing files in the project use `-`, match that instead. Avoid spaces.

### Object names

Use snake case (lower case with underscores `_`) for variable and function names. Prefer verbs for function names.

### Function calls

Never partially match function arguments with a unique prefix; use the full argument name instead.

Never omit argument names in a `switch()` statement.

### Control flow

Never use `&` and `|` inside an `if()` or `while()` condition because they can unexpectedly return vectors; always use `&&` and `||` instead.

### Returned values in functions

Only use `return()` for early returns. Otherwise, rely on R to return the result of the last evaluated expression.

### Comments

Use comments to explain the "why", and not the "what" or "how".

### Joins

In dplyr-based joins use `by = join_by()` syntax, such as `by = join_by(a == b)` instead of `by = c("a" = "b")`.

### Grouped operations

In general try to avoid `group_by() |> ... |> ungroup()` constructions because they are hard to read, as it is cognitively demanding to read code that only make sense when the grouped or partially grouped nature of the data is implicit.

Instead, use grouping arguments in the downstream operations when they are supported, like `.by` in `mutate` or `summarize`.

```r
# Avoid
result <- df |>
  group_by(g) |>
  mutate(x_mean = mean(x)) |>
  ungroup()

# Prefer
result <- df |>
  mutate(x_mean = mean(x), .by = g)
```

Only use `group_by()` when the grouping must persist across multiple operations and subsequent verbs have no grouping arguments.

### Iteration

Always use `map_*()` instead of `sapply`.

In general, prefer purrr-based functions over base apply functions. An exception to this rule is if you are developing a package where you are trying to minimize dependencies.

### Column-wise operations

Use `across()` for column-wise operations within a single `mutate()` call rather than a `for` loop:

```r
# Avoid
for (col in income_cols) {
  result <- result |> mutate(!!paste0("total_", col) := .data[[col]] * n)
}

# Prefer
result_scaled <- result |>
  mutate(across(all_of(income_cols), \(x) x * n, .names = "total_{.col}"))
```

When operations are more complex and `across()` becomes unwieldy, prefer pivoting to long format, computing, then pivoting back:

```r
result_scaled <- result |>
  pivot_longer(all_of(income_cols), names_to = "col", values_to = "avg") |>
  mutate(total = avg * n) |>
  pivot_wider(names_from = col, values_from = c(avg, total))
```

### Naming intermediate objects

Give each distinct stage of an analysis a descriptive name. Do not reuse the same object name for different things; doing so makes it hard to inspect intermediate results and debug errors.

```r
# Avoid
result <- compute_elderly(result)

# Prefer: distinct names
result_elderly  <- compute_elderly(result)
```
