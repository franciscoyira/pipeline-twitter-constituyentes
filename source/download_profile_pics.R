# Script goal: Download the profile pictures of the constituents

# Load packages
library(tidyverse)
library(here)
library(httr)

# Load the data
all_the_tweets <-
  list.files(here("data", "retrieved_tweets"),
             full.names = TRUE) %>%
  map_df(read_rds)

profile_pics_df <-
  all_the_tweets %>%
  distinct(screen_name, profile_image_url)

download_profile_pic <- function(url, screen_name) {
  GET(url,
      write_disk(here("data", "profile_pics", paste0(screen_name, ".jpg"))))

}

walk2(profile_pics_df$profile_image_url,
      profile_pics_df$screen_name,
      download_profile_pic)
