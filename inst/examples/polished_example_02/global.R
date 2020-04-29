library(shiny)
library(polished)
library(config)



app_config <- config::get()


# isolate database credentials
db_config <- app_config$db

# create database connection
db_conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = db_config$dbname,
  user = db_config$user,
  host = db_config$host,
  password = db_config$password
)


# configure polished
global_sessions_config(
  app_name = "polished_example_02",
  conn = db_conn,
  firebase_config = app_config$firebase
)
