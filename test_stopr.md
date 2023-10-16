---
title: "Test stopr::find_stops()"
output: 
  html_document:
    keep_md: true
date: "2023-10-16"
editor_options: 
  chunk_output_type: console
---



## Setup


```r
# Load packages, installing as needed
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, tibble, dplyr, lubridate, readr, scales, sf, knitr)
pacman::p_load_gh("brianhigh/stopr")
pacman::p_load_gh("stadiamaps/ggmap")

# Run a separate script to register the API key to use with Stadia Maps
# See: https://docs.stadiamaps.com/guides/migrating-from-stamen-map-tiles/
# register_stadiamaps("YOUR-API-KEY-HERE")
source(here("reg_api.R"))

# Define variables
gpx_file <- system.file("extdata", "test_data.gpx", package = "stopr")
stop_threshold_secs = 20
bbox_border <- 0.005
bbox_range_fraction <- 0.3
map_zoom <- 15
```

## Load data


```r
# Import GPX file
df <- st_read(gpx_file, layer = "track_points", quiet = TRUE) %>% 
   mutate(longitude = st_coordinates(.)[,1],
         latitude = st_coordinates(.)[,2],
         datetime = as_datetime(time))%>%
  as_tibble() %>% select(longitude, latitude, datetime)
```

## Find stops

Given a GPS track (coordinates and timestamps), find the stops on the route.


```r
# Find the stops on the route
stops <- find_stops(df, stop_min_duration_s = stop_threshold_secs)
```

## Show a list of stops


```r
kable(stops)
```



|start               |end                 | latitude| longitude| duration|
|:-------------------|:-------------------|--------:|---------:|--------:|
|2019-10-31 16:08:47 |2019-10-31 16:09:27 | 47.65846| -122.3178|       40|
|2019-10-31 16:09:46 |2019-10-31 16:10:06 | 47.65617| -122.3178|       20|
|2019-10-31 16:10:22 |2019-10-31 16:10:44 | 47.65598| -122.3148|       22|
|2019-10-31 16:11:54 |2019-10-31 16:12:28 | 47.65388| -122.3121|       34|
|2019-10-31 16:13:05 |2019-10-31 16:13:39 | 47.65209| -122.3109|       34|
|2019-10-31 16:14:10 |2019-10-31 16:21:43 | 47.65008| -122.3069|      453|
|2019-10-31 16:22:00 |2019-10-31 16:22:49 | 47.64881| -122.3060|       49|
|2019-10-31 16:25:40 |2019-10-31 16:26:59 | 47.65336| -122.3145|       79|
|2019-10-31 16:29:08 |2019-10-31 16:29:52 | 47.65724| -122.3167|       44|
|2019-10-31 16:29:55 |2019-10-31 16:30:41 | 47.65813| -122.3167|       46|
|2019-10-31 16:30:48 |2019-10-31 16:31:35 | 47.65913| -122.3167|       47|
|2019-10-31 16:31:37 |2019-10-31 16:32:31 | 47.66008| -122.3166|       54|
|2019-10-31 16:32:48 |2019-10-31 16:33:20 | 47.66101| -122.3157|       32|
|2019-10-31 16:35:01 |2019-10-31 16:35:21 | 47.65891| -122.3178|       20|

## Create bounding box for map


```r
# Prepare a data frame to use for making the bounding box of the basemap
center_lat <- mean(range(df$latitude))
center_lon <- mean(range(df$longitude))
border <- bbox_border
bbox.df <- data.frame(
  lat = c(center_lat - border, center_lat, center_lat + border),
  lon = c(center_lon - border, center_lon, center_lon + border))
bbox <- make_bbox(lon, lat, bbox.df, f = bbox_range_fraction)
```

## Create base map


```r
# Create the basemap from Stadia Map's "Toner Lite" tiles
basemap <- get_stadiamap(bbox, zoom = map_zoom, maptype = "stamen_toner_lite")
```

```
## ℹ © Stadia Maps © Stamen Design © OpenMapTiles © OpenStreetMap contributors.
```

## Create map


```r
# Create the map
p <- ggmap(basemap) +
  geom_point(mapping = aes(x = longitude, y = latitude),
             data = df, color = 'orange', size = 1, alpha = 0.6) +
  geom_point(mapping = aes(x = longitude, y = latitude,
                           size = log10(rescale(duration) + 1)/2),
             data = stops, color = 'darkred', alpha = 0.9) +
  theme_void() + theme(legend.position = "none") +
  labs(x = NULL, y = NULL, fill = NULL)
```

## Show map

![](test_stopr_files/figure-html/map-1.png)<!-- -->
