library(shiny)
library(polished)
library(config)

app_config <- config::get()

global_sessions_config(
  app_name = "polished_hosted_example",
  api_key = app_config$api_key_prod,
)

#global_sessions_config(
#  app_name = "polished_hosted_example",
#  api_key = app_config$api_key_dev,
#  api_version = "dev"
#)
