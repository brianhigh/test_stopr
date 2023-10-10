# Import the test GPS track data in GPX format and save as CSV.
# Note: The GPX file was exported from Geo Tracker version 4.0.2.1750 (Android).

# Filename: import_test_track_gpx.R
# Copyright (c) Brian High
# License: MIT https://opensource.org/licenses/MIT (See LICENSE file.)
# Repository: https://github.com/brianhigh/stopr

# Load packages.
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, tibble, plotKML, dplyr, lubridate, readr)

# Import GPX file.
gpx_path <- here("2022-01-01_Morning_Run.gpx")
df <- as_tibble(readGPX(gpx_path)$tracks[[1]][[1]]) %>% 
  select(-ele) %>% 
  rename(longitude = lon, latitude = lat, datetime = time) %>% 
  mutate(datetime = as_datetime(datetime))

# Save as CSV.
write_csv(df, here("test_data.csv"))
