# The change memo: what changed since the baseline release, and why it can be
# trusted. The baseline is read from git, outside the pipeline, so the memo
# target always reruns.

# ── Reading git ──

run_git <- function(args) {
  output <- suppressWarnings(system2(
    "git",
    shQuote(args),
    stdout = TRUE,
    stderr = FALSE
  ))
  if (!is.null(attr(output, "status"))) {
    return(NULL)
  }
  output
}

# The highest v* tag by version, or REALTALK_BASELINE if set
find_baseline_ref <- function(override = Sys.getenv("REALTALK_BASELINE")) {
  if (nzchar(override)) {
    return(override)
  }
  tags <- run_git(c("tag", "--list", "v*"))
  versions <- package_version(str_remove(tags, "^v"), strict = FALSE)
  tags <- tags[!is.na(versions)]
  versions <- versions[!is.na(versions)]
  if (length(tags) == 0) {
    cli_abort("No v* tags found. Set REALTALK_BASELINE to a git ref.")
  }
  tags[order(versions, decreasing = TRUE)][1]
}

read_csv_at_ref <- function(ref, path) {
  lines <- run_git(c("show", paste0(ref, ":", path)))
  if (is.null(lines)) {
    return(NULL)
  }
  read_csv(I(paste(lines, collapse = "\n")), show_col_types = FALSE)
}

processed_dataset_names <- function(dir = "data-raw/processed") {
  list.files(dir, pattern = "\\.csv$") |>
    str_remove("\\.csv$") |>
    setdiff("available_price_indexes")
}

read_processed <- function(names, ref = NULL, dir = "data-raw/processed") {
  paths <- file.path(dir, paste0(names, ".csv"))
  if (is.null(ref)) {
    datasets <- map(paths, \(path) read_csv(path, show_col_types = FALSE))
  } else {
    datasets <- map(paths, \(path) read_csv_at_ref(ref, path))
  }
  set_names(datasets, names)
}

# ── Comparing datasets ──

period_columns <- function(data) {
  intersect(c("year", "quarter", "month"), names(data))
}

add_period <- function(data) {
  if ("month" %in% names(data)) {
    data |>
      mutate(period = paste0(year, "m", month), index = year * 12 + month - 1)
  } else if ("quarter" %in% names(data)) {
    data |>
      mutate(
        period = paste0(year, "q", quarter),
        index = year * 4 + quarter - 1
      )
  } else {
    data |> mutate(period = as.character(year), index = year)
  }
}

# One row per period in either version, with the old and new values
join_versions <- function(old, new) {
  by <- period_columns(new)
  value <- setdiff(names(new), by)
  old <- old |> rename(old = all_of(value)) |> mutate(in_old = TRUE)
  new <- new |> rename(new = all_of(value)) |> mutate(in_new = TRUE)

  full_join(old, new, by = by) |>
    mutate(
      in_old = !is.na(in_old),
      in_new = !is.na(in_new),
      changed = in_old &
        in_new &
        (xor(is.na(old), is.na(new)) | abs(old - new) > 1e-9) %in% TRUE
    ) |>
    add_period() |>
    arrange(index)
}

summarize_changes <- function(name, old, new) {
  if (is.null(old)) {
    return(tibble(
      dataset = name,
      added = nrow(new),
      removed = 0L,
      revised = 0L
    ))
  }
  joined <- join_versions(old, new)
  revisions <- joined |> filter(changed)
  largest <- revisions |> slice_max(abs(new - old), n = 1, with_ties = FALSE)
  has_revisions <- nrow(revisions) > 0

  tibble(
    dataset = name,
    added = sum(joined$in_new & !joined$in_old),
    removed = sum(joined$in_old & !joined$in_new),
    revised = nrow(revisions),
    revised_range = if (has_revisions) {
      paste(first(revisions$period), "to", last(revisions$period))
    } else {
      ""
    },
    largest = if (has_revisions) {
      sprintf("%s: %s to %s", largest$period, largest$old, largest$new)
    } else {
      ""
    }
  )
}

latest_period <- function(data) {
  if (is.null(data)) {
    return("")
  }
  value <- setdiff(names(data), period_columns(data))
  data |>
    filter(!is.na(.data[[value]])) |>
    add_period() |>
    slice_max(index, n = 1) |>
    pull(period)
}

# Values that should never change: historical CPI-U NSA, which BLS never
# revises, and final C-CPI-U. A C-CPI-U value is final if it is 12 or more
# months older than the baseline's latest month: BLS makes interim values
# final 10 to 12 months after first publication.
find_unexpected_revisions <- function(baseline, current) {
  changed_values <- function(name) {
    join_versions(baseline[[name]], current[[name]]) |>
      filter(in_old, !is.na(old), changed | !in_new) |>
      mutate(dataset = name)
  }

  cpi_u <- changed_values("cpi_u_monthly_nsa")

  baseline_latest <- baseline$c_cpi_u_monthly_nsa |>
    add_period() |>
    pull(index) |>
    max()
  c_cpi_u <- changed_values("c_cpi_u_monthly_nsa") |>
    filter(baseline_latest - index >= 12)

  bind_rows(cpi_u, c_cpi_u) |>
    select(dataset, period, old, new)
}

# ── Stale hand-maintained inputs ──

find_stale_inputs <- function(current, today = Sys.Date()) {
  warnings <- character()

  rs_latest <- max(current$cpi_u_rs_annual$year)
  if (month(today) >= 6 && rs_latest < year(today) - 1) {
    warnings <- c(
      warnings,
      paste0(
        "CPI-U-RS has no annual value for ",
        year(today) - 1,
        ". BLS usually publishes it in the spring; update ",
        "`data-raw/raw/static/r-cpi-u-rs-allitems.csv`."
      )
    )
  }

  mw_latest <- max(current$us_minimum_wage_monthly$year)
  if (mw_latest < year(today)) {
    warnings <- c(
      warnings,
      paste0(
        "The monthly minimum wage ends in ",
        mw_latest,
        ". Update `final_year` in `data-raw/R/fed_mw.R`."
      )
    )
  }

  warnings
}

# ── The memo ──

memo_headline <- function(current) {
  paste0(
    "CPI-based data through ",
    month_label(latest_period(current$cpi_u_monthly_nsa)),
    "; PCE through ",
    month_label(latest_period(current$pce_monthly_sa))
  )
}

markdown_table <- function(data) {
  header <- paste0("| ", paste(names(data), collapse = " | "), " |")
  rule <- paste0("|", paste(rep("---", ncol(data)), collapse = "|"), "|")
  rows <- data |>
    mutate(across(everything(), as.character)) |>
    pmap_chr(\(...) paste0("| ", paste(c(...), collapse = " | "), " |"))
  c(header, rule, rows)
}

build_memo <- function(
  baseline_ref,
  baseline,
  current,
  fred_verification,
  today
) {
  names <- names(current)

  coverage <- tibble(
    dataset = names,
    before = map_chr(names, \(name) latest_period(baseline[[name]])),
    after = map_chr(names, \(name) latest_period(current[[name]]))
  )

  changes <- map(names, \(name) {
    summarize_changes(name, baseline[[name]], current[[name]])
  }) |>
    list_rbind() |>
    filter(added > 0 | removed > 0 | revised > 0)

  unexpected <- find_unexpected_revisions(baseline, current)
  stale <- find_stale_inputs(current, today)

  c(
    "## Data update memo",
    "",
    paste0("**", memo_headline(current), "**"),
    "",
    paste0("Compared with ", baseline_ref, ", the latest release."),
    "",
    "### Coverage",
    "",
    markdown_table(coverage),
    "",
    "### Changes",
    "",
    if (nrow(changes) > 0) markdown_table(changes) else "No changes.",
    "",
    "### Unexpected revisions",
    "",
    "Historical CPI-U NSA values never change, and neither do final C-CPI-U values.",
    "",
    if (nrow(unexpected) > 0) markdown_table(unexpected) else "None.",
    "",
    "### Verification against FRED",
    "",
    markdown_table(fred_verification),
    "",
    "### Stale hand-maintained inputs",
    "",
    if (length(stale) > 0) paste("-", stale) else "None."
  )
}

# `outputs` (the exported files) is only there so the memo runs after every
# dataset is written.
write_change_memo <- function(
  outputs,
  fred_verification,
  baseline_ref = find_baseline_ref(),
  path = "reports/change_memo.md",
  today = Sys.Date()
) {
  names <- processed_dataset_names()
  memo <- build_memo(
    baseline_ref,
    baseline = read_processed(names, ref = baseline_ref),
    current = read_processed(names),
    fred_verification = fred_verification,
    today = today
  )
  dir.create(dirname(path), showWarnings = FALSE)
  write_lines(memo, path)
  path
}
