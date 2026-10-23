# Tests for the pipeline's functions in data-raw/R. They need no network.
# Run from the package root: Rscript data-raw/tests/run.R

targets::tar_load_globals()
testthat::test_dir("data-raw/tests/testthat", stop_on_failure = TRUE)
