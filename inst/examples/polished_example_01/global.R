library(shiny)
library(polished)
# devtools::load_all("../../../../polished")
library(tychobratools)
library(config)



app_config <- config::get()

db_conn <- tychobratools::db_connect(app_config$db)


global_sessions_config(
  app_name = app_config$app_name,
  conn = db_conn,
  firebase_config = app_config$firebase
)
