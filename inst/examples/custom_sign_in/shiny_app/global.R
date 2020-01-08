library(shiny)
library(polished)
library(config)

app_config <- config::get()

db_conn <- tychobratools::db_connect(app_config$db)


global_sessions_config(
  app_name = app_config$app_name,
  firebase_functions_url = app_config$firebase_functions_url,
  conn = db_conn
)

