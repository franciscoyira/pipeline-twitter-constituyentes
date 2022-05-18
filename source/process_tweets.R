# Script goal: Consolidate the data available on the S3 bucket
# 'fyac-backend-data-constituyentes' and then consolidate it to create the .rds
# files that go onto 'fyac-final-data-twitter-constituyentes'

library(dplyr)
library(purrr)
library(aws.s3)
library(lubridate, include.only = c("floor_date", "days"))
library(forcats, include.only = "fct_reorder2")
library(stringr, include.only = "str_to_lower")
library(here)
library(magrittr, include.only = "%>%")
library(readr, include.only = "read_rds")

# Load the data
constituents_data <- read_rds(here("data",
                                   "datos_constituyentes_clean.rds"))

all_the_tweets_raw <- 
  get_bucket_df("fyac-backend-data-constituyentes") %>% 
  pull(Key) %>% 
  map_df(s3readRDS, bucket = "fyac-backend-data-constituyentes")

# all_the_tweets_raw <-
#   list.files(here("data", "retrieved_tweets"),
#              full.names = TRUE) %>%
#   map_df(read_rds)

all_the_tweets <- all_the_tweets_raw %>%
  mutate(screen_name_lower = str_to_lower(screen_name),
         day_created_at = as.Date(created_at)) %>%
  filter(!is_retweet) %>%
  mutate(total_engagement = favorite_count + retweet_count)

# Filter tweets from last week

end_last_week <- lubridate::floor_date(Sys.Date(),
                                       unit = "week",
                                       week_start = 7)

start_last_week <- end_last_week - lubridate::days(6)

tweets_last_week <-
  all_the_tweets %>%
  filter(between(day_created_at,
                 start_last_week,
                 end_last_week))

# RNK_TWEETS.RDS -----
# Create ranking of tweets with more engagement during last week
rnk_tweets <-
  tweets_last_week %>%
  arrange(desc(total_engagement))

# write_rds(rnk_tweets,
#           here("data", "rnk_tweets.rds"))

s3saveRDS(rnk_tweets,
          object = "rnk_tweets.rds",
          bucket = "fyac-final-data-twitter-constituyentes")


# DF_PLOT_COALITIONS.RDS ----
all_the_tweets2 <- all_the_tweets_raw %>%
  mutate(screen_name_lower = str_to_lower(screen_name),
         day_created_at = as.Date(created_at),
         week = lubridate::floor_date(day_created_at,
                                      unit = "week",
                                      week_start = 1)) %>%
  filter(!is_retweet,
         day_created_at >= lubridate::ymd(20210601)) %>%
  mutate(total_engagement = favorite_count + retweet_count) %>%
  left_join(
    constituents_data %>%
      mutate(twitter_handle = str_to_lower(twitter_handle)),
    by = c("screen_name_lower" = "twitter_handle")
  )

# Data wrangling
df_plot_coalitions <-
  all_the_tweets2 %>%
  count(lista_grouped,
        week,
        wt = total_engagement,
        name = "total_engagement") %>%
  mutate(lista_grouped = fct_reorder2(lista_grouped,
                                      week,
                                      total_engagement))

# write_rds(df_plot_coalitions, here("data", "df_plot_coalitions.rds"))

s3saveRDS(df_plot_coalitions,
          object = "df_plot_coalitions.rds",
          bucket = "fyac-final-data-twitter-constituyentes")

# RNK_TOTAL_ENGAGEMENT.RDS ----
rnk_total_engagement <-
  tweets_last_week %>%
  count(screen_name, screen_name_lower,
        wt = total_engagement,
        name = "total_engagement",
        sort = TRUE) %>%
  left_join(
    constituents_data %>%
      mutate(twitter_handle = str_to_lower(twitter_handle)),
    by = c("screen_name_lower" = "twitter_handle")
  )

s3saveRDS(rnk_total_engagement,
          object = "rnk_total_engagement.rds",
          bucket = "fyac-final-data-twitter-constituyentes")
