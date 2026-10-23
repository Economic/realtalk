# Helpers for "Draft update": the next version number and the NEWS.md entry.
# data-raw/prepare_update.R applies them to DESCRIPTION and NEWS.md.

today_eastern <- function(now = Sys.time()) {
  as_date(with_tz(now, "America/New_York"))
}

# YYYY.M.D for `date`, with .1, .2, ... when that version is already released.
# Older tags were zero padded (v2026.02.13), so versions are compared as
# versions, not as text.
next_version <- function(date, released_tags) {
  released <- package_version(str_remove(released_tags, "^v"), strict = FALSE)
  released <- released[!is.na(released)]
  base <- paste(year(date), month(date), day(date), sep = ".")

  candidate <- base
  suffix <- 0
  while (package_version(candidate) %in% released) {
    suffix <- suffix + 1
    candidate <- paste(base, suffix, sep = ".")
  }
  candidate
}

month_label <- function(period) {
  date <- ym(str_replace(period, "m", "-"))
  paste(month(date, label = TRUE, abbr = FALSE), year(date))
}

# The terse NEWS.md lines, from what moved since the baseline
news_entry <- function(baseline, current) {
  moved <- function(name) {
    latest_period(baseline[[name]]) != latest_period(current[[name]])
  }

  lines <- character()
  if (moved("cpi_u_monthly_nsa")) {
    lines <- c(
      lines,
      paste(
        "update CPI-based data through",
        month_label(latest_period(current$cpi_u_monthly_nsa))
      )
    )
  }
  if (moved("pce_monthly_sa")) {
    lines <- c(
      lines,
      paste(
        "update PCE through",
        month_label(latest_period(current$pce_monthly_sa))
      )
    )
  }
  if (moved("cpi_u_rs_annual")) {
    lines <- c(
      lines,
      paste("update CPI-U-RS through", latest_period(current$cpi_u_rs_annual))
    )
  }
  if (length(lines) == 0) {
    lines <- "update with revised data"
  }
  paste("*", lines)
}
