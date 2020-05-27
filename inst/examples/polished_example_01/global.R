library(shiny)
library(polished)
library(config)


app_config <- config::get()


# isolate database credentials
# db_config <- app_config$db
#
# # create database connection
# db_conn <- DBI::dbConnect(
#   RPostgres::Postgres(),
#   dbname = db_config$dbname,
#   user = db_config$user,
#   host = db_config$host,
#   password = db_config$password
# )
# schema <- "polished"
# hashed_cookie <- "eddb55937f8a95f0a1cad3c8aece8b9f"
# account_uid <- "0b112eb8-2dbe-48fa-95ae-6900c262f470"

DBI::dbGetQuery(
  db_conn,
  paste0('SELECT uid AS session_uid, user_uid, email, email_verified, app_uid, signed_in_as FROM ',
         schema, '.sessions WHERE hashed_cookie=$1 AND is_signed_in=$2 AND account_uid=$3'),
  params = list(
    hashed_cookie,
    TRUE,
    account_uid
  )
)


# configure polished
global_sessions_config(
  app_name = "polished_example_01",
  api_key = "ZkYyWz9giNhTTc4va5nJ22G3VpGUIU4eTw",
  api_url = "http://localhost:8080"
)
