# Sets the version in DESCRIPTION and adds its NEWS.md entry, after tar_make()
# has rebuilt the data. Run from the package root; "Draft update" runs it in CI.
# It changes files outside the pipeline's outputs, so it isn't a target.

source("data-raw/packages.R")
tar_source("data-raw/R")

baseline_ref <- find_baseline_ref()
names <- processed_dataset_names()
baseline <- read_processed(names, ref = baseline_ref)
current <- read_processed(names)

version <- next_version(today_eastern(), run_git(c("tag", "--list", "v*")))
desc_set_version(version)

write_lines(
  c(paste("## Version", version), news_entry(baseline, current), "", read_lines("NEWS.md")),
  "NEWS.md"
)

cli_inform("Version {version}, compared with {baseline_ref}.")
