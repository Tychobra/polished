library(shiny)
library(polished)
library(config)
library(shinyjs)

app_config <- config::get()

# configure polished
global_sessions_config(
  app_name = "polished_example_04",
  api_key = app_config$api_key,
  sentry_dsn = list(
    "r" = app_config$sentry_dsn$r,
    "js" = app_config$sentry_dsn$js
  )
)
