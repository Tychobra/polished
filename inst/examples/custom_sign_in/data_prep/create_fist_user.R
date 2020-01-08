# this file is supposed tp be execute with its working directory set to
# the "custom_sign_in/" directory that contains the "data_prep" directory which contains
# this file.  It assumes you have already set up your polished schema for another
# app, so all you need to get this app running is add a new user.
library(polished)

# you will need your own config file
db_config <- config::get(file = "shiny_app/config.yml")$db

db_conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = db_config$dbname,
  host = db_config$host,
  password = db_config$password,
  user = db_config$user
)

polished::create_app_user(
  db_conn,
  email = "demo@tychobra.com",
  app_name = "custom_sign_in",
  is_admin = TRUE
)

DBI::dbDisconnect(db_conn)
