# On library(realtalk), says when the data is two or more months behind and
# r-universe has a newer version (issue #27). It stays quiet otherwise: when the
# data is current, when nothing newer is available yet, when the check can't
# reach r-universe, outside interactive sessions, in renv projects (which pin
# versions on purpose), and when options(realtalk.update_check = FALSE).

.onAttach <- function(libname, pkgname) {
  if (!should_check_for_update()) {
    return()
  }

  latest <- latest_cpi_month(realtalk::cpi_u_monthly_nsa)
  if (months_behind(latest, Sys.Date()) < 2) {
    return()
  }

  # At most once a day. The date is recorded before asking r-universe, so an
  # offline session pays the timeout once a day, not every session.
  if (checked_today(Sys.Date())) {
    return()
  }
  record_check(Sys.Date())

  message <- update_message(
    latest = latest,
    installed = as.character(utils::packageVersion(pkgname)),
    available = fetch_available_version()
  )
  if (!is.null(message)) {
    packageStartupMessage(message)
  }
}

should_check_for_update <- function(
  is_interactive = interactive(),
  enabled = getOption("realtalk.update_check", TRUE),
  renv_project = Sys.getenv("RENV_PROJECT")
) {
  is_interactive && !isFALSE(enabled) && renv_project == ""
}

# The date of the last check is kept in R's per-package cache folder. If it
# can't be read or written, the check runs as if it hadn't run today.
last_check_file <- function() {
  file.path(tools::R_user_dir("realtalk", "cache"), "last-update-check")
}

checked_today <- function(today, file = last_check_file()) {
  last <- tryCatch(
    as.Date(readLines(file, n = 1, warn = FALSE)),
    error = function(e) NA,
    warning = function(w) NA
  )
  isTRUE(last == today)
}

record_check <- function(today, file = last_check_file()) {
  tryCatch(
    {
      dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
      writeLines(format(today), file)
    },
    error = function(e) NULL,
    warning = function(w) NULL
  )
  invisible()
}

# The year and month of the latest non-missing value
latest_cpi_month <- function(data) {
  data <- data[!is.na(data$cpi_u), ]
  last <- which.max(data$year * 12 + data$month)
  c(year = data$year[last], month = data$month[last])
}

# Whole months from `latest` to the month of `today`. CPI for a month comes out
# in the middle of the next month, so 1 is normal.
months_behind <- function(latest, today) {
  today_year <- as.integer(format(today, "%Y"))
  today_month <- as.integer(format(today, "%m"))
  (today_year * 12 + today_month) - (latest[["year"]] * 12 + latest[["month"]])
}

# The version r-universe serves, or NA if it can't be reached
fetch_available_version <- function(
  repos = "https://economic.r-universe.dev",
  timeout = 3
) {
  old <- options(timeout = timeout)
  on.exit(options(old))
  tryCatch(
    {
      available <- utils::available.packages(repos = repos, type = "source")
      if ("realtalk" %in% rownames(available)) {
        available["realtalk", "Version"]
      } else {
        NA_character_
      }
    },
    error = function(e) NA_character_,
    warning = function(w) NA_character_
  )
}

# The startup message, or NULL when updating wouldn't help: nothing newer is
# available, or r-universe couldn't be reached
update_message <- function(latest, installed, available) {
  if (is.na(available)) {
    return(NULL)
  }
  if (package_version(available) <= package_version(installed)) {
    return(NULL)
  }
  paste0(
    "realtalk's data runs through ",
    month.name[latest[["month"]]],
    " ",
    latest[["year"]],
    ", and version ",
    available,
    " is available. Update with\n",
    "  install.packages(\"realtalk\", repos = \"https://economic.r-universe.dev\")\n",
    "Turn this message off with options(realtalk.update_check = FALSE)."
  )
}
