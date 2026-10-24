# The new-data reminder's issue title and body. `changed` are the snapshot
# files that differ from the newest proposed data (the open draft, or main);
# `snapshots` are the fresh snapshots, named by file stem; `stale` are the
# stale-input warnings.
new_data_notice <- function(changed, snapshots, stale = character()) {
  cpi <- month_label(latest_period(snapshots$cpi_u_nsa))
  pce <- month_label(latest_period(snapshots$pce_monthly_sa))

  body <- c(
    "BLS or BEA has new or revised data that isn't in a draft yet:",
    "",
    paste0("- `", changed, "`"),
    "",
    paste0("Latest: CPI-based data through ", cpi, "; PCE through ", pce, "."),
    "",
    "Next: run **Draft update** from the Actions tab.",
    if (length(stale) > 0) {
      c("", "Hand-maintained inputs to check:", "", paste("-", stale))
    }
  )

  list(
    title = paste0("New data: CPI through ", cpi, ", PCE through ", pce),
    body = body
  )
}
