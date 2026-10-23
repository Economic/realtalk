# Checks shared by test-data-consistency.R. Each returns the offending periods
# as labels such as "2025m10", so a failing test names them. They use base R
# only, since the package suggests nothing but testthat.

frequency_of <- function(data) {
  if ("month" %in% names(data)) {
    "monthly"
  } else if ("quarter" %in% names(data)) {
    "quarterly"
  } else {
    "annual"
  }
}

period_index <- function(data) {
  switch(
    frequency_of(data),
    monthly = data$year * 12L + data$month - 1L,
    quarterly = data$year * 4L + data$quarter - 1L,
    annual = data$year
  )
}

period_label <- function(index, frequency) {
  if (length(index) == 0) {
    return(character())
  }
  switch(
    frequency,
    monthly = paste0(index %/% 12L, "m", index %% 12L + 1L),
    quarterly = paste0(index %/% 4L, "q", index %% 4L + 1L),
    annual = as.character(index)
  )
}

value_column <- function(data) {
  setdiff(names(data), c("year", "quarter", "month"))
}

missing_month_index <- function(missing) {
  missing$year * 12L + missing$month - 1L
}

# Periods between the first and last that have no row or an NA value. Known
# missing months may be absent or NA.
find_gaps <- function(data, missing = known_missing_months) {
  data <- as.data.frame(data)
  frequency <- frequency_of(data)
  index <- period_index(data)
  observed <- index[!is.na(data[[value_column(data)]])]
  expected <- seq(min(index), max(index))
  if (frequency == "monthly") {
    expected <- setdiff(expected, missing_month_index(missing))
  }
  period_label(setdiff(expected, observed), frequency)
}

find_duplicates <- function(data) {
  data <- as.data.frame(data)
  index <- period_index(data)
  period_label(unique(index[duplicated(index)]), frequency_of(data))
}

# Periods from `from_year` on where the two series differ by more than
# `tolerance`, skipping periods in `skip` (period indexes).
find_disagreements <- function(a, b, tolerance, from_year = 2000, skip = NULL) {
  a <- as.data.frame(a)
  b <- as.data.frame(b)
  frequency <- frequency_of(a)
  a_values <- setNames(a[[value_column(a)]], period_index(a))
  b_values <- setNames(b[[value_column(b)]], period_index(b))
  first_index <- switch(
    frequency,
    monthly = from_year * 12L,
    quarterly = from_year * 4L,
    annual = from_year
  )
  common <- intersect(names(a_values), names(b_values))
  common <- common[as.integer(common) >= first_index]
  common <- setdiff(common, as.character(skip))
  difference <- abs(a_values[common] - b_values[common])
  off <- common[!is.na(difference) & difference > tolerance + 1e-9]
  period_label(as.integer(off), frequency)
}

# Quarterly or annual periods whose monthly source doesn't cover every month,
# counting a known missing month as present.
find_incomplete_periods <- function(
  aggregated,
  monthly,
  missing = known_missing_months
) {
  aggregated <- as.data.frame(aggregated)
  monthly <- as.data.frame(monthly)
  frequency <- frequency_of(aggregated)
  month_index <- period_index(monthly)[!is.na(monthly[[value_column(monthly)]])]
  month_index <- union(month_index, missing_month_index(missing))
  per_period <- if (frequency == "quarterly") 3L else 12L
  group <- if (frequency == "quarterly") {
    (month_index %/% 12L) * 4L + (month_index %% 12L) %/% 3L
  } else {
    month_index %/% 12L
  }
  counts <- table(group)
  complete <- as.integer(names(counts)[counts == per_period])
  period_label(setdiff(period_index(aggregated), complete), frequency)
}

# Quarters (as period indexes) that contain a known missing month
quarters_with_missing_months <- function(missing = known_missing_months) {
  missing$year * 4L + (missing$month - 1L) %/% 3L
}
