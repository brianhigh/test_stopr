---
title: "Test stopr::find_stops()"
output: 
  html_document:
    keep_md: true
date: "2023-10-10"
editor_options: 
  chunk_output_type: console
---



## Setup


```r
# Load packages, installing as needed
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, tibble, plotKML, dplyr, lubridate, readr, scales, knitr)
pacman::p_load_gh("brianhigh/stopr")
pacman::p_load_gh("stadiamaps/ggmap")

# Run a separate script to register the API key to use with Stadia Maps
# See: https://docs.stadiamaps.com/guides/migrating-from-stamen-map-tiles/
# register_stadiamaps("YOUR-API-KEY-HERE")
source(here("reg_api.R"))

# Define variables
gpx_file <- here("2022-01-01_Morning_Run.gpx")
csv_file <- here("test_data.csv")
stop_threshold_secs = 45
```

## Import GPX file and save as CSV


```r
# Import GPX file
df <- as_tibble(readGPX(gpx_file)$tracks[[1]][[1]]) %>% 
  select(-ele) %>% 
  rename(longitude = lon, latitude = lat, datetime = time) %>% 
  mutate(datetime = as_datetime(datetime))

# Save as CSV
write_csv(df, csv_file)
```

## Load data and find stops

Given a GPS track (coordinates and timestamps), find the stops on the route.


```r
# Import the test data for a route
df <- read_csv(csv_file, show_col_types = FALSE)

# Find the stops on the route
stops <- find_stops(df, stop_min_duration_s = stop_threshold_secs)
```

## Show a list of stops


```r
kable(stops)
```



|start               |end                 | latitude| longitude| duration|
|:-------------------|:-------------------|--------:|---------:|--------:|
|2022-01-01 14:42:08 |2022-01-01 14:43:05 | 42.32782| -71.10874|       57|
|2022-01-01 14:47:51 |2022-01-01 14:48:50 | 42.32687| -71.11300|       59|
|2022-01-01 14:49:28 |2022-01-01 14:50:16 | 42.32511| -71.11404|       48|
|2022-01-01 14:51:51 |2022-01-01 14:53:06 | 42.32279| -71.11682|       75|
|2022-01-01 14:53:42 |2022-01-01 14:54:42 | 42.32098| -71.11686|       60|
|2022-01-01 14:58:36 |2022-01-01 14:59:26 | 42.31469| -71.11876|       50|
|2022-01-01 14:59:46 |2022-01-01 15:00:48 | 42.31397| -71.12020|       62|
|2022-01-01 15:03:54 |2022-01-01 15:04:49 | 42.31820| -71.12370|       55|
|2022-01-01 15:05:54 |2022-01-01 15:06:41 | 42.32027| -71.12201|       47|
|2022-01-01 15:07:27 |2022-01-01 15:08:35 | 42.32112| -71.12014|       68|
|2022-01-01 15:08:37 |2022-01-01 15:09:22 | 42.31997| -71.12018|       45|
|2022-01-01 15:10:38 |2022-01-01 15:11:25 | 42.31875| -71.11785|       47|
|2022-01-01 15:19:38 |2022-01-01 15:20:25 | 42.31977| -71.12272|       47|
|2022-01-01 15:21:40 |2022-01-01 15:22:42 | 42.32110| -71.12004|       62|
|2022-01-01 15:26:40 |2022-01-01 15:27:35 | 42.31601| -71.11743|       55|
|2022-01-01 15:29:00 |2022-01-01 15:29:50 | 42.31399| -71.12000|       50|
|2022-01-01 15:32:12 |2022-01-01 15:33:18 | 42.31688| -71.12315|       66|
|2022-01-01 15:36:17 |2022-01-01 15:37:33 | 42.32102| -71.11993|       76|
|2022-01-01 15:38:56 |2022-01-01 15:39:44 | 42.31909| -71.11879|       48|
|2022-01-01 15:41:01 |2022-01-01 15:42:10 | 42.31890| -71.11708|       69|
|2022-01-01 15:42:12 |2022-01-01 15:42:58 | 42.32006| -71.11718|       46|
|2022-01-01 15:43:00 |2022-01-01 15:43:59 | 42.32090| -71.11665|       59|
|2022-01-01 15:45:03 |2022-01-01 15:45:55 | 42.32128| -71.11400|       52|
|2022-01-01 15:46:23 |2022-01-01 15:47:23 | 42.32185| -71.11210|       60|
|2022-01-01 15:48:01 |2022-01-01 15:48:58 | 42.32416| -71.11212|       57|
|2022-01-01 15:48:59 |2022-01-01 15:50:09 | 42.32488| -71.11209|       70|

## Create bounding box for map


```r
# Prepare a data frame to use for making the bounding box of the basemap
center_lat <- mean(range(df$latitude))
center_lon <- mean(range(df$longitude))
border <- 0.005
bbox.df <- data.frame(
  lat = c(center_lat - border, center_lat, center_lat + border),
  lon = c(center_lon - border, center_lon, center_lon + border))
```

## Create base map


```r
# Create the basemap
bbox <- make_bbox(lon, lat, bbox.df, f = .4)
basemap <- get_stadiamap(bbox, zoom = 15, maptype = "stamen_terrain")
```

```
## ℹ © Stadia Maps © Stamen Design © OpenMapTiles © OpenStreetMap contributors.
```

## Create map


```r
# Create the plot
p <- ggmap(basemap) +
  geom_point(mapping = aes(x = longitude, y = latitude),
             data = df, color = 'darkorange', size = 1, alpha = 0.7) +
  geom_point(mapping = aes(x = longitude, y = latitude,
                           size = log10(rescale(duration) + 1)/2),
             data = stops, color = 'darkred', alpha = 0.7) +
  theme_void() + theme(legend.position = "none") +
  labs(x = NULL, y = NULL, fill = NULL)
```

## Show map

![](test_stopr_files/figure-html/map-1.png)<!-- -->
