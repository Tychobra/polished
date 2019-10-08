library(polished)
library(config)
library(RPostgres)
library(DBI)

app_config <- config::get(file = "shiny_app/config.yml")

db_conn <- tychobratools::db_connect(app_config$db)

create_schema(db_conn)

create_first_user(
  db_conn,
  app_name = "polished_example_01",
  email = "demo@tychobra.com"
)

DBI::dbDisconnect(conn)
