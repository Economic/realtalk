# The new-data reminder's check: fetches every source the pipeline fetches,
# and compares the snapshots with REALTALK_COMPARE_REF (the open draft's
# branch, or main). Writes reports/reminder/changed ("true" or "false") and,
# when something changed, title.txt and body.md. Run from the package root;
# new-data-check.yml runs it.

source("data-raw/packages.R")
tar_source("data-raw/R")

compare_ref <- Sys.getenv("REALTALK_COMPARE_REF", "origin/main")
tar_make(names = ends_with("_raw_csv"))

changed <- run_git(c(
  "diff",
  "--name-only",
  compare_ref,
  "--",
  "data-raw/raw/snapshots"
))
if (is.null(changed)) {
  cli_abort("Couldn't compare the snapshots with {compare_ref}.")
}

out <- "reports/reminder"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
write_lines(
  if (length(changed) > 0) "true" else "false",
  file.path(out, "changed")
)

if (length(changed) == 0) {
  cli_inform("No new data compared with {compare_ref}.")
} else {
  snapshot_files <- list.files(
    "data-raw/raw/snapshots",
    pattern = "\\.csv$",
    full.names = TRUE
  )
  snapshots <- snapshot_files |>
    set_names(str_remove(basename(snapshot_files), "\\.csv$")) |>
    map(\(path) read_csv(path, show_col_types = FALSE))
  stale <- find_stale_inputs(
    read_processed(processed_dataset_names()),
    today_eastern()
  )

  notice <- new_data_notice(basename(changed), snapshots, stale)
  write_lines(notice$title, file.path(out, "title.txt"))
  write_lines(notice$body, file.path(out, "body.md"))
  cli_inform("New data compared with {compare_ref}: {basename(changed)}.")
}
