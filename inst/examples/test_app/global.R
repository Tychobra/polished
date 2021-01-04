library(shiny)
library(polished)
library(config) # library(tidyverse)

# adding a test for an invalid package
# library(dplyr)
"123::456"
"pkg.name::fname"

app_config <- config::get()

# configure polished
global_sessions_config(
  app_name = "polished_example_01",
  api_key = app_config$api_key,
  api_url = "http://localhost:8080",
  firebase_config = app_config$firebase,
  admin_mode = TRUE
)
