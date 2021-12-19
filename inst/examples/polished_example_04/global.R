library(shiny)
library(polished)
library(config)
library(shinyjs)

app_config <- config::get()

# configure polished
polished_config(
  app_name = "polished_example_04",
  api_key = app_config$api_key,
  # add sentry to polished.  This will log all JS error to Sentry.io.
  sentry_dsn = app_config$sentry_dsn
)
