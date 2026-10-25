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

# NEWS.md with the new version's entry on top. If the top entry is for a
# version that was never released (a change merged between data updates), its
# lines are folded into the new entry rather than left under a heading no
# release has.
add_news_entry <- function(news, version, entry, released_tags) {
  headings <- which(str_detect(news, "^## Version "))
  if (length(headings) > 0) {
    top_version <- str_remove(news[headings[1]], "^## Version ")
    released <- package_version(str_remove(released_tags, "^v"), strict = FALSE)
    released <- released[!is.na(released)]
    if (!package_version(top_version, strict = FALSE) %in% released) {
      section_end <- if (length(headings) > 1) headings[2] - 1 else length(news)
      carried <- news[(headings[1] + 1):section_end]
      entry <- c(entry, carried[carried != ""])
      news <- news[-(headings[1]:section_end)]
    }
  }
  c(paste("## Version", version), entry, "", news)
}
