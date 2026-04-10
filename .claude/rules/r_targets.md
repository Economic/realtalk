# Guidance for using targets-based workflows in R

If the general targets scaffolding (`_targets.R`, etc.) does not exist, create

- `packages.R`: for all `library()` calls
- `_targets.R`: for the pipeline
- `R/`: for all functions

## Development workflow

Re-run the targets pipeline after any changes: `Rscript -e 'targets::tar_make()'`. 

To inspect targets interactively or in ad hoc scripts, first call `targets::tar_load_globals()` to load all packages and functions, then use `tar_load()` or `tar_read()` to access built targets.

## `_targets.R`

`_targets.R` should have the following structure

```
source("packages.R")
tar_source()

## targets pipeline goes here
```
## Pipeline conventions

Use `tar_assign()` from the `tarchetypes` package instead of a simple list.  

Every assignment inside `tar_assign` must pipe into (or be wrapped by) a target factory — `tar_target()`, `tar_file()`, `tar_file_read()`, etc. A bare `my_target <- f(input)` without `tar_target()` will fail. 

Prefer `f(x) |> tar_target()` over `tar_target(f(x))` — the pipe style reads top-to-bottom as "compute, then store."

Here is a complete example showing the preferred syntax for regular targets, file inputs, and file outputs together inside one `tar_assign` block:

```
tar_assign({
  raw_file <- "data.csv" |>
    tar_file()

  raw_data <- read_csv(raw_file) |>
    tar_target()

  result <- analyze(raw_data) |>
    tar_target()

  output_file <- write_output(result) |>
    tar_file()
})
```

## File targets

For tracking input or output files, do not use `tar_target(format = "file")` but instead use `tar_file()` from `tarchetypes`.

If an input file can be parsed easily without a complicated set of arguments use `tar_file_read()` from `tarchetypes`.

```
data_input <- "data_input.csv" |>
  tar_file_read(read_csv(file = !!.x, show_col_types = FALSE))
```

## Functions

Functions in `R/` should be side-effect free.

Except for very simple pipelines, do not put all functions in a single script in `R/`. Instead ask what certain functions have in common and put them in a file named after that commonality. 

## Packages

All packages should be loaded in packages.R. Do not use syntax like `package::function()` inside pipeline code and functions in `R/`.

Use `library(conflicted)` and `conflicts_prefer()` to resolve all conflicts.

Use `renv` only if explicitly requested or already initialized.

## Pipeline structure

Default to wide pipelines that split work into independent targets reading from shared upstream targets, rather than long linear chains. Wide pipelines cache better during iterative development. Go long only when steps are genuinely sequential with no branching consumers.

## Branching

For dynamic branching patterns and aggregation, use the `targets-branching` skill.
