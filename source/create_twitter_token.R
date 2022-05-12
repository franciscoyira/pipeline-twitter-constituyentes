# Goal of the script: setting up the Twitter token
library(keyring)
library(rtweet)

twitter_token <- create_token(
  app = "pacto-social-1",
  consumer_key =
    keyring::key_get("pacto-social-1-consumer_key"),
  consumer_secret =
    keyring::key_get("pacto-social-1-consumer_secret"),
  access_token =
    keyring::key_get("pacto-social-1-access_token"),
  access_secret =
    keyring::key_get("pacto-social-1-access_secret"),
  set_renv = TRUE)
