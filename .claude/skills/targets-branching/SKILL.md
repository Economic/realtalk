---
name: targets-branching
description: Dynamic branching patterns and aggregation in targets pipelines. Use when creating branched targets with pattern = map(), setting up parameter targets, or handling branch aggregation.
user-invocable: false
---

# Dynamic branching in targets

Use dynamic branching with `pattern = map()` inside `tar_assign()`. Do not use static branching (`tar_map()`) because `tar_assign()` injects the left-hand side of each assignment as the `name` argument into the right-hand side function call, and `tar_map()` does not have a `name` argument (its first argument is `values`).

## Parameter targets

Define a parameter target that returns a one-row-per-group tibble, then branch over it:

```r
tar_assign({
  params = make_params() |>
    tar_target()

  result = compute(data, params$group_var) |>
    tar_target(pattern = map(params))
})
```

Use `NA` (not `NULL`) for unused parameter values, since data frame rows cannot hold `NULL`.

## How dynamic branch aggregation works

When a downstream target consumes a branched target *without* its own `pattern`, targets automatically aggregates all branches. The aggregation behavior depends on the object type:

- **Data frames** are row-bound. The aggregated result has no column identifying which branch produced each row. If downstream targets need to distinguish branches, carry a group identifier (e.g. `age_label`) through the data from the start.
- **Non-data-frame objects** (e.g. ggplot objects) cannot be row-bound and will error. Use `iteration = "list"` on the branched target so branches aggregate into a list:

```r
  my_plot = make_plot(branch_data, params$label) |>
    tar_target(pattern = map(branch_data, params), iteration = "list")

  combined = combine_plots(my_plot) |>
    tar_target()
```

## Writing functions for aggregated branches

Functions that consume aggregated branches should expect the aggregated form directly — a single data frame (not a list of data frames) or a list of non-df objects. Do not write functions that `map()` over a list of data frames when the input will be one row-bound data frame.
