suppressMessages({
  library(shiny)
  library(shinydashboard)
  library(tychobratools)
  library(shinyjs)
  library(polished)
  library(config)
  library(dplyr)
})

# set config env to "default" if running app locally for development, and set it to
# production if running on shinyapps.io.
polished::set_config_env()

app_config <- config::get()

db_conn <- tychobratools::db_connect(app_config$db)

polished::global_sessions_config(
  app_name = app_config$app_name,
  firebase_project_id = app_config$firebase$projectId,
  conn = db_conn,
  authorization_level = "all"
)
