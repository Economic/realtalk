create_c_cpi_u_extended_annual <- function(
  c_cpi_u_annual,
  cpi_u_annual,
  cpi_u_x1_annual,
  cpi_u_rs_annual
) {
  c_cpi_u_annual |>
    full_join(cpi_u_annual, by = "year") |>
    full_join(cpi_u_x1_annual, by = "year") |>
    full_join(cpi_u_rs_annual, by = "year") |>
    mutate(cpi_late = if_else(year >= 2000, c_cpi_u, NA)) |>
    mutate(cpi_early = if_else(year <= 1967, cpi_u, NA)) |>
    chain_to_base_annual(cpi_u_rs, cpi_late, 2000) |>
    chain_to_base_annual(cpi_u_x1, cpi_u_rs, 1978) |>
    chain_to_base_annual(cpi_early, cpi_u_x1, 1967) |>
    mutate(
      value = case_when(
        year <= 1966 ~ cpi_early,
        year >= 1967 & year <= 1977 ~ cpi_u_x1,
        year >= 1978 & year <= 1999 ~ cpi_u_rs,
        year >= 2000 ~ cpi_late
      )
    ) |>
    select(year, c_cpi_u_extended = value) |>
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) |>
    arrange(year)
}

create_c_cpi_u_extended_monthly_nsa <- function(
  c_cpi_u_extended_annual,
  c_cpi_u_monthly_nsa,
  cpi_u_monthly_nsa,
  cpi_u_annual,
  cpi_u_x1_monthly_nsa,
  cpi_u_x1_annual,
  cpi_u_rs_monthly_nsa,
  cpi_u_rs_annual,
  known_missing
) {
  cpi_u_ann_ratio <- cpi_u_monthly_nsa |>
    rename(cpi_u_monthly = cpi_u) |>
    inner_join(cpi_u_annual, by = "year") |>
    rename(cpi_u_annual = cpi_u) |>
    mutate(cpi_u_ratio = cpi_u_monthly / cpi_u_annual) |>
    select(year, month, cpi_u_ratio)

  cpi_u_x1_ann_ratio <- cpi_u_x1_monthly_nsa |>
    rename(cpi_u_x1_monthly = cpi_u_x1) |>
    inner_join(cpi_u_x1_annual, by = "year") |>
    rename(cpi_u_x1_annual = cpi_u_x1) |>
    mutate(cpi_u_x1_ratio = cpi_u_x1_monthly / cpi_u_x1_annual) |>
    select(year, month, cpi_u_x1_ratio)

  cpi_u_rs_ann_ratio <- cpi_u_rs_monthly_nsa |>
    rename(cpi_u_rs_monthly = cpi_u_rs) |>
    inner_join(cpi_u_rs_annual, by = "year") |>
    rename(cpi_u_rs_annual = cpi_u_rs) |>
    mutate(cpi_u_rs_ratio = cpi_u_rs_monthly / cpi_u_rs_annual) |>
    select(year, month, cpi_u_rs_ratio)

  cpi_u_ann_ratio |>
    full_join(cpi_u_x1_ann_ratio, by = c("year", "month")) |>
    full_join(cpi_u_rs_ann_ratio, by = c("year", "month")) |>
    full_join(c_cpi_u_monthly_nsa, by = c("year", "month")) |>
    rename(cpi_monthly = c_cpi_u) |>
    full_join(c_cpi_u_extended_annual, by = "year") |>
    rename(cpi_annual = c_cpi_u_extended) |>
    mutate(
      value = case_when(
        year <= 1966 ~ cpi_u_ratio * cpi_annual,
        year >= 1967 & year <= 1977 ~ cpi_u_x1_ratio * cpi_annual,
        year >= 1978 & year <= 1999 ~ cpi_u_rs_ratio * cpi_annual,
        year >= 2000 ~ cpi_monthly
      )
    ) |>
    select(year, month, c_cpi_u_extended = value) |>
    interpolate_missing_months(c_cpi_u_extended, known_missing) |>
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) |>
    arrange(year, month)
}

create_c_cpi_u_extended_monthly_sa <- function(
  c_cpi_u_extended_monthly_nsa,
  cpi_u_monthly_nsa,
  cpi_u_monthly_sa,
  known_missing
) {
  cpi_u_monthly_nsa |>
    rename(cpi_u_nsa = cpi_u) |>
    inner_join(cpi_u_monthly_sa, by = c("year", "month")) |>
    rename(cpi_u_sa = cpi_u) |>
    inner_join(c_cpi_u_extended_monthly_nsa, by = c("year", "month")) |>
    mutate(
      sa_factor = cpi_u_sa / cpi_u_nsa,
      c_cpi_u_extended = c_cpi_u_extended * sa_factor
    ) |>
    select(year, month, c_cpi_u_extended) |>
    interpolate_missing_months(c_cpi_u_extended, known_missing) |>
    mutate(c_cpi_u_extended = round(c_cpi_u_extended, digits = 1)) |>
    arrange(year, month)
}
