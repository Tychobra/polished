library(shiny)
#detach("package:polished", unload=TRUE)
library(polished)
library(config)


app_config <- config::get()

# configure polished
global_sessions_config(
  app_name = "polished_example_01",
  api_key = app_config$api_key,
  api_url = "http://localhost:8080",
  firebase_config = app_config$firebase
)
