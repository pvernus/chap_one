install.packages("ecmwfr")
library("ecmwfr")

install.packages('PCICt')
install.packages('https://pacificclimate.org/R/climdex.pcic_1.1-11.tar.gz')

library(climdex.pcic)

wf_set_key()

request <- list(
  dataset_short_name = "derived-era5-single-levels-daily-statistics",
  product_type = "reanalysis",
  variable = "10m_u_component_of_wind",
  year = "1979",
  month = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"),
  day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
  daily_statistic = "daily_maximum",
  time_zone = "utc+00:00",
  frequency = "3_hourly",
  area = c(54, -180, -42, 180),
  target = "era5-wind-max-test.nc"
)

file <- wf_request(
  request  = request,  # the request
  transfer = TRUE,     # download the file
  path     = "source/treatment/era5"       # store data in current working directory
)

#####
#####

install.packages("ecmwfr")
install.packages("purrr")

library("ecmwfr")
library("purrr")

wf_set_key()

years <- 1979:1989

download_year <- function(year) {
  request <- list(
    dataset_short_name = "derived-era5-single-levels-daily-statistics",
    product_type = "reanalysis",
    variable = "10m_u_component_of_wind",
    year = as.character(year),
    month = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"),
    day = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"),
    daily_statistic = "daily_maximum",
    time_zone = "utc+00:00",
    frequency = "3_hourly",
    area = c(54, -180, -42, 180),
    target = paste0("era5-wind-max-", year, ".nc")
    )    

  wf_request(
    request  = request,
    transfer = TRUE,
    path     = "source/treatment/era5"
  )
}

map(years, download_year)
