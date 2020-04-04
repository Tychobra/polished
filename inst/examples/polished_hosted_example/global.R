library(shiny)
library(polished)
library(config)

app_config <- config::get()

global_sessions_config(
  app_name = app_config$app_name,
  api_key = app_config$polished_key
)
