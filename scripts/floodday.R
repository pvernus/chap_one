
## Define the directory
data_path <- here::here('data', 'mswep')

## Define the file pattern
# sd: values = nb of days w/ SPI1 >= +2.0
sd_files <- list.files(data_path, pattern = "^floodday_sd.*\\.dta$", full.names = TRUE)
# max: values = cum.sum precipitation (mm) for x wettest day(s)
max_files <- list.files(data_path, pattern = "^floodday_max.*\\.dta$", full.names = TRUE)

## Import all .dta files into a list
data_sd_list <- lapply(sd_files, haven::read_dta)
data_max_list <- lapply(max_files, haven::read_dta)

## Name the list
# sd
names(data_sd_list) <- sapply(basename(sd_files), function(x) {
  substr(x, nchar(x) - 6, nchar(x) - 4) # Extract the last three characters before ".dta"
})
# max
names(data_max_list) <- sapply(basename(max_files), function(x) {
  substr(x, nchar(x) - 7, nchar(x) - 4) # Extract the last three characters before ".dta"
})

## Clean variables' names
data_sd_list <- lapply(data_sd_list, janitor::clean_names) # sd
data_max_list <- lapply(data_max_list, janitor::clean_names) # max

## Pivot from wide to long
# sd 
data_sd_list <- lapply(data_sd_list, function(df) {
  pivot_longer(df, 
               cols = -geo_id, 
               names_to = "year", 
               names_prefix = "test", 
               values_to = "value")
})
# max
data_max_list <- lapply(data_max_list, function(df) {
  pivot_longer(df, 
               cols = -geo_id, 
               names_to = "year", 
               names_prefix = "m", 
               values_to = "value")
})

## rename value columns
# sd
data_sd_list <- lapply(names(data_sd_list), function(name) {
  df <- data_sd_list[[name]]
  colnames(df)[colnames(df) == "value"] <- name
  df
})
# max
data_max_list <- lapply(names(data_max_list), function(name) {
  df <- data_max_list[[name]]
  colnames(df)[colnames(df) == "value"] <- name
  df
})

## join elements of the list
# sd
data_sd <- reduce(data_sd_list, function(x, y) {
  full_join(x, y, by = c("geo_id", "year"))
})
# max
data_max <- reduce(data_max_list, function(x, y) {
  full_join(x, y, by = c("geo_id", "year"))
})

## visualize trends (mean, median, IQR)
## density
# sd
data_sd |> 
  pivot_longer(cols = starts_with("sd"), names_to = "index", values_to = "value") |>
  ggplot(aes(x = value, group=index)) +
  geom_density(aes(colour=index, fill = index), alpha = .3) +
  theme_light()
# max
data_max |> 
  pivot_longer(cols = starts_with("max"), names_to = "index", values_to = "value") |>
  ggplot(aes(x = value, group=index)) +
  geom_density(aes(colour=index, fill = index), alpha = .3) +
  theme_light()

## mean
# sd
summarize(data_sd,
          sd2 = mean(sd2),
          sd3 = mean(sd3),
          sd4 = mean(sd4),
          .by = "year") |> 
  pivot_longer(cols = starts_with("sd"), names_to = "index", values_to = "value") |> 
  ggplot(aes(x = year, y = value, group=index)) +
  geom_line(aes(colour = index)) +
  labs(y = "Mean number of days") +
  theme_light()
# max
summarize(data_max,
          max1 = mean(max1),
          max3 = mean(max3),
          max4 = mean(max4),
          max5 = mean(max5),
          .by = "year") |> 
  pivot_longer(cols = starts_with("max"), names_to = "index", values_to = "value") |> 
  ggplot(aes(x = year, y = value, group=index)) +
  geom_line(aes(colour = index)) +
  labs(y = "Mean cumulative precipitation (mm)") +
  theme_light()
 
## median
# sd
summarize(data_sd,
          sd2 = median(sd2),
          sd3 = median(sd3),
          sd4 = median(sd4),
          .by = "year") |> 
  pivot_longer(cols = starts_with("sd"), names_to = "index", values_to = "value") |> 
  ggplot(aes(x = year, y = value, group=index)) +
  geom_line(aes(colour = index)) +
  labs(y = "Median number of days") +
  theme_light()
# max
summarize(data_max,
          max1 = median(max1),
          max3 = median(max3),
          max4 = median(max4),
          max5 = median(max5),
          .by = "year") |> 
  pivot_longer(cols = starts_with("max"), names_to = "index", values_to = "value") |> 
  ggplot(aes(x = year, y = value, group=index)) +
  geom_line(aes(colour = index)) +
  labs(y = "Median cumulative precipitation (mm)") +
  theme_light()

## IQR
# sd
summarize(data_sd,
          sd2 = IQR(sd2),
          sd3 = IQR(sd3),
          sd4 = IQR(sd4),
          .by = "year") |> 
  pivot_longer(cols = starts_with("sd"), names_to = "index", values_to = "value") |> 
  ggplot(aes(x = year, y = value, group=index)) +
  geom_line(aes(colour = index)) +
  geom_smooth(aes(colour = index)) +
  labs(y = "IQR number of days") +
  theme_light()
# max
summarize(data_max,
          max1 = IQR(max1),
          max3 = IQR(max3),
          max4 = IQR(max4),
          max5 = IQR(max5),
          .by = "year") |> 
  pivot_longer(cols = starts_with("max"), names_to = "index", values_to = "value") |> 
  ggplot(aes(x = year, y = value, group=index)) +
  geom_line(aes(colour = index)) +
  labs(y = "IQR cumulative precipitation (mm)") +
  theme_light()

## merge precipitation data 
data_preci <- data_sd |> 
  filter(year >= 2000) |> 
  left_join(data_max, by = c("geo_id", "year"))

# NOTE: why is there one geo_id==NA?
data_preci <- data_preci[!is.na(data_preci$geo_id),]

### merge gdis and em-dat
# Load datasets
load(here('data', 'data_emdat_clean.RData')) # EM-DAT
load(here('source', 'gdis', 'pend-gdis-1960-2018-disasterlocations.rdata')) # GDIS

## select vars
# emdat
data_emdat_short <- data_emdat |> 
  select(dis_no, classification_key, disaster_type, iso, country, location, start_year, end_year, last_update) |> 
  filter(start_year <= 2018) |> # time period
  filter(grepl("nat-hyd-flo|nat-cli-dro|nat-met-ext|nat-met-sto", classification_key)) |> # disaster type
  mutate(disasterno = stringr::str_sub(dis_no, end = -5)) |> 
  filter(country != "Canary Islands") |> # iso code
  mutate(iso3c = countrycode(sourcevar = country,
                             origin = "country.name",
                             destination = "iso3c"
  ))

# gdis
data_gdis <- sf::st_set_geometry(GDIS_disasterlocations, NULL) # remove geometry
data_gdis_short <- data_gdis |> 
  select(disasterno, dis_id = id, geo_id, disastertype, iso3, country) |> 
  mutate(year = as.numeric(substr(data_gdis$disasterno, 1, 4))) |> # time period
  filter(year > 1999) |> 
  mutate(disastertype = trimws(disastertype)) |> # disaster type
  filter(disastertype %in% c("flood", "drought", "extreme temperature", "storm")) |> 
  mutate(iso3c = countrycode(sourcevar = country,
                             origin = "country.name",
                             destination = "iso3c"
  )) |> 
  mutate(iso3c = case_when(
    country=="Micronesia" ~ "FSM",
    country=="Kosovo" ~ "XXK",
    .default = iso3c))

# TO DO: need to deal with Serbia Montenegro. 
# Kosovo, Montenegro, and Serbia are mixed between gdis and emdat
# n.b. gdis use a unique iso3 for each geo_id

## merge gdis and emdat (by = disasterno)
join_gdis_emdat <- left_join(data_gdis_short, data_emdat_short, 
                             by = c("disasterno", "iso3c"),
                             suffix = c("_gdis", "_emdat"))

# NOTE: one location is located in South Sudan by GDIS but in Sudan by EM-DAT
# country_gdis=='South Sudan' & disasterno=='2007-0261'

# NOTE: key variable between gdis and emdat is 'disasterno'. the ID-variable for specific disasters. 
# however, a disaster can occur in several countries in the same country. 
# i find some disasterno in gdis but not in emdat, which is weird. Why? is it due to updates in emdat which deleted/changes some disasterno?

## Missing data
# by disaster type
join_gdis_emdat |> 
  filter(is.na(dis_no)) |> 
  tabyl(disastertype) |> 
  arrange(desc(n))
# by country
join_gdis_emdat |> 
  filter(is.na(dis_no)) |> 
  tabyl(iso) |> 
  arrange(desc(n))
# number of country per disaster-ID with missing data in em-dat
join_gdis_emdat |> 
  filter(is.na(dis_no)) |>
  summarize(n = n_distinct(iso3c), .by = disasterno) |> 
  arrange(desc(n))
    
## merge disaster and precipitation datasets (by = geo_id)
data_ext_dis <- left_join(data_preci, join_gdis_emdat, 
          by = "geo_id",
          suffix = c("_mswep", "_dis"))

# Missing data
data_ext_dis |> 
  filter(is.na(dis_no)) |> 
  View()

# NOTE: issues w/ ex-Yugoslovia iso + South Sudan (disasterno=='2007-0261') + Ukraine/Russia (disasterno=='2002-0482')

### check period, dis type

## create disaster_year dummy
data_ext_dis <- data_ext_dis |> 
  mutate(year_dis_dummy = ifelse(year_mswep == year_dis, "Flood", "No Flood"))

# comparative stats
data_ext_dis |> 
  tbl_summary(include = c(starts_with("sd"), starts_with("max")), 
              by = year_dis_dummy) |> 
  add_p()

# Boxplot
data_ext_dis |> 
  pivot_longer(cols = sd2:max5, names_to = "index", values_to = "value") |> 
  ggplot(aes(x = year_dis_dummy, y = value)) +
  geom_boxplot(outliers = FALSE) +
  facet_wrap(~index, scales = "free_y") +
  theme_light() +
  labs(y = "Nb of days (sd) / total mm (max)")

ggbetweenstats(data_ext_dis, year_dis_dummy, sd2,
               # to remove violin plot
               violin.args = list(width = 0, linewidth = 0),
               # to remove boxplot
               boxplot.args = list(width = 0),
               # to remove points
               point.args = list(alpha = 0)
)

#
df <- data_ext_dis |> 
  select(geo_id, year_mswep, year_dis_dummy, sd2:max5) |> 
  pivot_longer(cols = sd2:max5, names_to = "index", values_to = "value") |> 
  mutate(max = max(value), .by = c("geo_id", "index")) |> 
  mutate(max_year_dummy = ifelse(value >= max, 1, 0), .by = c("geo_id", "index"))

lprop(xtabs(~ year_dis_dummy + max_year_dummy, df))

lprop(xtabs(~ year_dis_dummy + max_year_dummy, df |> filter(index=="sd2")))
lprop(xtabs(~ year_dis_dummy + max_year_dummy, df |> filter(index=="sd3")))
lprop(xtabs(~ year_dis_dummy + max_year_dummy, df |> filter(index=="sd4")))

lprop(xtabs(~ year_dis_dummy + max_year_dummy, df |> filter(index=="max1")))
lprop(xtabs(~ year_dis_dummy + max_year_dummy, df |> filter(index=="max3")))
lprop(xtabs(~ year_dis_dummy + max_year_dummy, df |> filter(index=="max4")))
lprop(xtabs(~ year_dis_dummy + max_year_dummy, df |> filter(index=="max5")))

summarize(df,
          max = sum(max_year_dummy),
          .by = c(year_mswep, index)) |> 
  mutate(year_mswep = as.integer(year_mswep)) |> 
  ggplot(aes(x = year_mswep, y = max)) +
  geom_line() + 
  facet_wrap(~index, scales = "free_y", nrow = 2, ncol = 4) +
  theme_light() +
  labs(x = "Year", y = "total mm (max) / # days (sd)", title = "When did maximum index values happened?")


data_ext_dis |> 
  select(iso3c, geo_id, year_mswep, year_dis_dummy, sd2:max5) |> 
  mutate(outcome = ifelse(year_dis_dummy == 'Flood', 1, 0)) |> 
  fixest::feglm(outcome ~ mvsw(sd2, sd3, sd4, max1, max3, max4, max5) | iso3c^geo_id + year_mswep, vcov = "twoway")






# check if max yearly value by geo_id unit in floodday match w/ dis occurence in gdis (summarize dis_dummy mean(max) ; tab dis_dummy max_dummy)
# merge gdis and emdat (by = disasterno)
# ...