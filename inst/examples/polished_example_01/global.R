library(shiny)
library(polished)
library(config)

Sys.setenv(R_CONFIG_ACTIVE = "axion")

app_config <- config::get()

db_conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = app_config$db$host,
  dbname = app_config$db$dbname,
  password = app_config$db$password,
  user = app_config$db$user
)


global_sessions_config(
  app_name = app_config$app_name,
  firebase_project_id = app_config$firebase$projectId,
  conn = db_conn
)
