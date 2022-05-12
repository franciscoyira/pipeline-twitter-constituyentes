# Initialise Twitter token
library(rtweet)

twitter_token <- create_token(
  app = "pacto-social-1",
  consumer_key = 
    Sys.getenv("consumer_key"),
  consumer_secret = 
    Sys.getenv("consumer_secret"),
  access_token = 
    Sys.getenv("access_token"),
  access_secret =
    Sys.getenv("access_secret"),
  set_renv = TRUE)