library(shiny)
library(polished)
library(config)

app_config <- config::get()

# configure polished
polished_config(
  app_name = "polished_example_01",
  api_key = app_config$api_key
)
