# PCE, monthly available 1959+
# PCE, annual available 1929+
# BEA_API_KEY <- Sys.getenv("BEA_API_KEY")
# beaSpecs <- list(
#   'UserID' = BEA_API_KEY ,
#   'Method' = 'GetData',
#   'datasetname' = 'NIPA',
#   'TableName' = 'T20804',
#   'Frequency' = 'M',
#   'Year' = 'X'
# )
# bea.R::beaGet(beaSpecs, asWide = FALSE) %>%
#   as_tibble() %>%
#   janitor::clean_names() %>%
#   filter(line_number == 1) %>%
#   select(time_period, data_value) %>%
#   write_csv("data-raw/raw/pce_monthly_sa.csv")
#
# beaSpecs <- list(
#   'UserID' = BEA_API_KEY ,
#   'Method' = 'GetData',
#   'datasetname' = 'NIPA',
#   'TableName' = 'T20304',
#   'Frequency' = 'A',
#   'Year' = 'X'
# )
# bea.R::beaGet(beaSpecs, asWide = FALSE) %>%
#   as_tibble() %>%
#   janitor::clean_names() %>%
#   filter(line_number == 1) %>%
#   select(time_period, data_value) %>%
#   write_csv("data-raw/raw/pce_annual.csv")

create_pce <- function(raw_monthly_csv, raw_annual_csv) {
  ### MONTHLY
  monthly_sa_csv <- "data-raw/processed/pce_monthly_sa.csv"
  monthly_sa_rda <- "data/pce_monthly_sa.rda"

  pce_monthly_sa <- read_csv(raw_monthly_csv) %>%
    mutate(
      date = ym(time_period),
      year = year(date),
      month = month(date)
    ) %>%
    select(year, month, pce = data_value)

  pce_monthly_sa %>%
    write_csv(monthly_sa_csv)

  usethis::use_data(pce_monthly_sa, overwrite = TRUE)

  output_monthly <- c(monthly_sa_csv, monthly_sa_rda)


  ### ANNUAL
  annual_csv <- "data-raw/processed/pce_annual.csv"
  annual_rda <- "data/pce_annual.rda"

  pce_annual <- read_csv(raw_annual_csv) %>%
    select(year = time_period, pce = data_value)

  pce_annual %>%
    write_csv(annual_csv)

  usethis::use_data(pce_annual, overwrite = TRUE)

  output_annual <- c(annual_csv, annual_rda)

  ### ALL FILENAMES
  output <- c(output_monthly, output_annual)
  output
}
