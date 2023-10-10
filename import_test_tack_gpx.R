# Import the test GPS track data in GPX format and save as CSV.

# Filename: import_test_track_gpx.R
# Copyright (c) Brian High
# License: MIT https://opensource.org/licenses/MIT (See LICENSE file.)
# Repository: https://github.com/brianhigh/test_stopr

# Load packages.
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, tibble, plotKML, dplyr, lubridate, readr)

# Define variables
gpx_path <- here("2022-01-01_Morning_Run.gpx")
csv_path <- here("test_data.csv")

# Import GPX file.
df <- as_tibble(readGPX(gpx_path)$tracks[[1]][[1]]) %>% 
  select(-ele) %>% 
  rename(longitude = lon, latitude = lat, datetime = time) %>% 
  mutate(datetime = as_datetime(datetime))

# Save as CSV.
write_csv(df, csv_path)
