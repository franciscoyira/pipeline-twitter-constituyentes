library(cronR)

cmd <- cron_rscript(
  rscript = "/home/rstudio/pipeline-twitter-constituyentes/source/cronjob_pipeline.R",
  log_timestamp = FALSE,
  workdir = "/home/rstudio/pipeline-twitter-constituyentes/"
)

cron_add(
  command = cmd,
  frequency = 'daily',
  at = '16:30',
  days_of_week = 2,
  id = "Data Pipeline"
)
