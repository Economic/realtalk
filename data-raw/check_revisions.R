# Fails if a historical CPI-U NSA value or a final C-CPI-U value changed since
# the latest release. check.yml runs it from the package root.

source("data-raw/packages.R")
tar_source("data-raw/R")

baseline_ref <- find_baseline_ref()
names <- c("cpi_u_monthly_nsa", "c_cpi_u_monthly_nsa")
unexpected <- find_unexpected_revisions(
  baseline = read_processed(names, ref = baseline_ref),
  current = read_processed(names)
)

if (nrow(unexpected) > 0) {
  print(unexpected, n = Inf)
  cli_abort("{nrow(unexpected)} unexpected revision{?s} since {baseline_ref}.")
}
cli_inform("No unexpected revisions since {baseline_ref}.")
