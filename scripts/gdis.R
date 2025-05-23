# Load pckg
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  here,
  tidyverse,
  sf,
  tmap,
  tmaptools,
  countrycode,
  codebookr
)

# Load datasets
load(here('source', 'gdis', 'pend-gdis-1960-2018-disasterlocations.rdata')) # GDIS
load(here('data', 'data_emdat_clean.RData')) # EM-DAT
load(here('data', 'data_oecd_crs_clean.RData')) # CRS


# recipient names
recipient_name <- distinct(data_crs, recipient_name) |> 
  filter(!grepl("regional", recipient_name)) |> 
  mutate(iso3c = countrycode(sourcevar = recipient_name,
                             origin = "country.name",
                             destination = "iso3c")
  ) |> 
  mutate(iso3c = case_when(
    recipient_name=="Micronesia" ~ "FSM",
    recipient_name=="Kosovo" ~ "XXK",
    .default = iso3c
  ))

# load GDIS dataset
data_gdis = GDIS_disasterlocations
# recreate object with a recent coordinate reference system
st_crs(data_gdis) <- sf::st_crs(data_gdis, value = "EPSG:4326")
# add iso3c variable
data_gdis <- data_gdis |> 
  mutate(iso3c = countrycode(sourcevar = country,
                    origin = "country.name",
                    destination = "iso3c"
  )) |> 
  mutate(iso3c = case_when(
    country=="Micronesia" ~ "FSM",
    country=="Kosovo" ~ "XXK",
    .default = iso3c
  ))

# filter for recipient countries only
data <- merge(recipient_name, data_gdis, by = "iso3c", all.x = TRUE) |> 
# filter for relevant period
  mutate(year = as.integer(substr(disasterno, 1, 4))) |> 
  filter(year >= 2000) |> 
# filter for disaster type
  filter(disastertype == "flood")
# Convert to an sf object
data = st_as_sf(data)

head(data)

World <- st_read(here("source", "ne_10m_admin_0_map_units", "ne_10m_admin_0_map_units.shp")) |> 
  janitor::clean_names() |> 
  select(sovereignt, sov_a3, name, name_long, iso_a3, iso_a3_eh)

sf_use_s2(FALSE)
sf::st_is_valid(World, reason = T)
World <- st_make_valid(World)
sf::st_is_valid(World)

tm_shape(World) + 
  tm_borders() +
  tm_shape(data) +
  tm_dots(col = "year", title = "Disaster Type", palette = "Set1", alpha = .4, border.alpha = .3) +
  tm_layout(title = "Global Disaster Events", legend.outside = TRUE)

# summarize data at the country-year level
data_flood <- st_drop_geometry(data) |> 
  summarize(
          flood = length(disasterno),
          .by = iso3c)

data_flood_year <- st_drop_geometry(data) |> 
  summarize(
    flood = length(disasterno),
    .by = c(iso3c, year))

# add iso3c variable to tmap World dataset
world_iso3 <- World |> 
  mutate(name = as.character(name),
         iso3c = countrycode(sourcevar = iso_a3_eh,
                             origin = "iso3c",
                             destination = "iso3c")
  ) |> 
  #  filter(is.na(iso3c)) |> 
  #  distinct(sovereignt, name)  
  mutate(iso3c = ifelse(sovereignt=="Kosovo", "XXK", iso3c)) |> 
  filter(!is.na(iso3c))

world_disaster <- right_join(world_iso3, data_flood, by = "iso3c")
world_disaster_year <- right_join(world_iso3, data_flood_year, by = "iso3c", relationship = "many-to-many")

tm_shape(world_iso3) + 
  tm_borders() +
  tm_shape(world_disaster) +
  tm_polygons(col = "flood", style = "quantile", palette = "viridis", title = "Nb. of events (quantiles)") +
  tm_layout(main.title = "Floods, 2000-2018", main.title.position = c("left", "top"), legend.outside = TRUE)

tm_shape(world_iso3) + 
  tm_borders() +
  tm_shape(world_disaster_year) +
  tm_polygons(col = "flood", style = "quantile", palette = "viridis", title = "Nb. of events (quantiles)") +
  tm_facets(by = "year", free.scales = FALSE) +
  tm_layout(main.title = "Floods", main.title.position = c("left", "top"),
            outer.margins	= c(.1, .1, .1, .1))

# legend.outside = TRUE,

## Prepare dataset for analysis

# Remove geography to ease data operations
data_gdis <- st_drop_geometry(GDIS_disasterlocations)

# Remove whitespaces
data_gdis$disastertype <- str_squish(data_gdis$disastertype)
data_gdis$disasterno <- str_squish(data_gdis$disasterno)

# Convert to data.frame
data_gdis <- as.data.frame(data_gdis)
# Add ISO3-char to the locations
data_gdis$iso3c <- countrycode(sourcevar = data_gdis[, "country"],
                                           origin = "country.name",
                                           destination = "iso3c")
# Some values were not matched unambiguously: Kosovo, Micronesia
data_gdis <- data_gdis |> 
  mutate(iso3=ifelse(country=="Micronesia", "FSM", iso3c)) |> 
  mutate(iso3=ifelse(country=="Kosovo", "XXK", iso3c))

# create unique ID for each disaster geoloc
data_gdis <- data_gdis|> 
  mutate(disaster_geo_id = paste(disasterno, geo_id, sep = "-")) |> 
  relocate(disaster_geo_id)

data_gdis <- data_gdis |> 
  select(disasterno, disastertype, iso3c, country) |> 
  unique()

save(data_gdis, file = here("data", "data_gdis.RData"))
# st_write(GDIS_disasterlocations_sample, dsn=here("data","gpkg_GDIS_disasterlocations_sample.gpkg"), layer='disasterlocations')



### EM-DAT ###
emdat <- data_emdat |> 
  mutate(disasterno=substr(dis_no, 1, nchar(dis_no)-4),
         year=substr(dis_no, 1, 4)) |> 
  select(disasterno, classification_key, recipient_id, recipient_name, start_year, end_year)
  








merge(unique(emdat_id$disasterno), unique(gdis_id$disasterno))


left_join(emdat_id, gdis_id)

info_emdat <- data_emdat |> 
  select(dis_no, classification_key, recipient_id, recipient_name, start_year, end_year) |> 
  # Remove the ISO3 code from disasterno to enable merge with GDIS
  mutate(disasterno=substr(dis_no, 1, nchar(dis_no)-4),
         year=substr(dis_no, 1, 4)) |> 
  relocate(disasterno, .after=dis_no)

# NOTE: not sure disasterno = dis_no


# Additional stat. desc.
tbl_GDIS_disasterlocations_sample <- GDIS_disasterlocations_sample |> 
  select(-geometry) |> 
  as_tibble()

# country
summarize(tbl_GDIS_disasterlocations_sample,
          n = n_distinct(disasterno),
          .by = country) |> 
  arrange(desc(n))

# disaster type
summarize(tbl_GDIS_disasterlocations_sample,
          n = n_distinct(disasterno),
          .by = disastertype) |> 
  arrange(desc(n))

# country & disaster type
summarize(tbl_GDIS_disasterlocations_sample,
          n = n_distinct(disasterno),
          .by = c(country, disastertype)) |> 
  arrange(desc(n))
