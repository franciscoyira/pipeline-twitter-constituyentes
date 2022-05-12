# Goal of the script: iterate over constituents twitter handles to retrieve
# their timelines
library(dplyr)
library(readr)
library(stringr)
library(magrittr, include.only = "%>%")
library(lubridate, include.only = "floor_date")
library(here)
library(rtweet)
library(aws.s3)

# This requires having a token set up
# You can do it with the script source/create_twitter_token.rds

# Retrieving the list
datos_constituyentes <- read_rds(here("data", "datos_constituyentes_clean.rds"))

usernames <- datos_constituyentes %>%
  # I should have used NA for the people without Twitter account, but whatever
  filter(twitter_handle != "") %>%
  pull(twitter_handle)

last_sunday <- lubridate::floor_date(Sys.Date(), unit = "week", week_start = 7)
last_monday <- lubridate::floor_date(Sys.Date(), unit = "week", week_start = 1)

# Retrieve files in the bucket
rds_in_bucket <- 
  get_bucket_df(bucket = "fyac-backend-data-constituyentes",
              max = Inf)

for (username in usernames) {

  message(paste0("@", username))


# 1. Try to restore saved data, if it exists
  filenames_current_user <-
    rds_in_bucket %>% 
    filter(str_detect(Key, username)) %>% 
    pull(Key)
  
previous_data_exists <- length(filenames_current_user) > 0

my_since_id <- NULL # default value (for "first time" flow)
more_than_1week_since_last_file <- TRUE # default value

if (previous_data_exists) {
  # sort alphabetically (my naming convention allows that) and read
  # the most recent file
  most_recent_file <- sort(filenames_current_user, decreasing = TRUE)[[1]]

   # Check here if it has passed at least one week since the last file.
  # If yes, skip the current user and move onto the next one (to save API calls)
  date_most_recent_file <- most_recent_file %>%
    str_extract("^\\d{8}") %>%
    lubridate::ymd()

  more_than_1week_since_last_file <- date_most_recent_file < last_sunday

}


if (more_than_1week_since_last_file) {
  
  if (previous_data_exists) {
    message("Attempting to read last file from S3")
    most_recent_data <- s3readRDS(most_recent_file,
                                  bucket ="fyac-backend-data-constituyentes")
    
    my_since_id <-
      most_recent_data %>%
      slice_max(order_by = created_at, with_ties = FALSE) %>%
      pull(status_id)
  }
  
  df_iteration_tweets <-
    rtweet::get_timeline(username, n = 3200, since_id = my_since_id)

  message("Data retrieval from API completed")
} else {
  message("Not enough time since last retrieval. Skipping API call")
  next
}

# keeps tweets only up to last sunday
# this in order to retrieve data in a weekly basis (complete weeks)
if ("created_at" %in% colnames(df_iteration_tweets)) {
  df_iteration_tweets <-
    df_iteration_tweets %>%
    filter(created_at < last_monday)
}

# This DF will be empty if it hasn't passed more than a week since the last file
# WHEN TO SAVE? I'm almost sure that checking for nrow > 0 (plus previous
# conditions) is enough

if (nrow(df_iteration_tweets) > 0) {
  week_ind <- Sys.Date() %>%
    lubridate::floor_date(unit = "week", week_start = 7) %>%
    str_replace_all("-", "")

  filename <- paste0(week_ind, "_", username, ".rds")
  
  s3saveRDS(df_iteration_tweets,
            object = filename,
            bucket = "fyac-backend-data-constituyentes")
  
  message("New data written to S3")

} else {
   message("No new tweets from this user since last week. No data was written.")
 }
}
