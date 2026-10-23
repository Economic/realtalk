fred_series <- tribble(
  ~dataset              , ~value_col , ~series_id    ,
  "cpi_u_monthly_nsa"   , "cpi_u"    , "CPIAUCNS"    ,
  "cpi_u_monthly_sa"    , "cpi_u"    , "CPIAUCSL"    ,
  "c_cpi_u_monthly_nsa" , "c_cpi_u"  , "SUUR0000SA0" ,
  "pce_monthly_sa"      , "pce"      , "PCEPI"
)

# Compares the latest months of each dataset in `fred_series` with FRED.
# `datasets` is a named list of those datasets. Returns one row per dataset;
# stops the pipeline on any mismatch.
verify_against_fred <- function(
  datasets,
  months = 24,
  api_key = Sys.getenv("FRED_API_KEY"),
  require_key = Sys.getenv("REALTALK_REQUIRE_FRED") == "true",
  fetch = get_fred
) {
  if (!nzchar(api_key)) {
    if (require_key) {
      cli_abort("FRED_API_KEY is not set, and REALTALK_REQUIRE_FRED is true.")
    }
    cli_warn("FRED_API_KEY is not set, so the FRED verification did not run.")
    return(tibble(
      dataset = fred_series$dataset,
      series_id = fred_series$series_id,
      status = "not run"
    ))
  }

  ours <- fred_series |>
    pmap(\(dataset, value_col, series_id) {
      datasets[[dataset]] |>
        filter(!is.na(.data[[value_col]])) |>
        slice_tail(n = months) |>
        transmute(dataset, series_id, year, month, ours = .data[[value_col]])
    }) |>
    list_rbind()

  start <- ours |>
    summarize(start = min(make_date(year, month, 1))) |>
    pull(start)

  fred <- fetch(
    fred_series$series_id,
    start = start,
    fred_api_key = api_key
  ) |>
    transmute(series_id, year, month, fred = value)

  compared <- ours |>
    left_join(fred, by = join_by(series_id, year, month)) |>
    mutate(
      period = paste0(year, "m", month),
      # FRED and our datasets both carry three decimals for these months
      mismatch = !is.na(fred) & abs(round(ours, 3) - round(fred, 3)) > 1e-9
    )

  mismatches <- compared |> filter(mismatch)
  if (nrow(mismatches) > 0) {
    details <- mismatches |>
      mutate(
        detail = paste0(dataset, " ", period, ": ", ours, " vs FRED ", fred)
      ) |>
      pull(detail)
    cli_abort(c(
      "Datasets differ from FRED:",
      set_names(details, rep("*", length(details)))
    ))
  }

  compared |>
    summarize(
      first = first(period),
      last = last(period),
      months_checked = sum(!is.na(fred)),
      not_on_fred = paste(period[is.na(fred)], collapse = ", "),
      .by = c(dataset, series_id)
    ) |>
    mutate(status = "verified")
}
