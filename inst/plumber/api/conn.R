library(RPostgres)
library(DBI)

db_config <- config::get()$db

create_conn <- function() {
  DBI::dbConnect(
    RPostgres::Postgres(),
    dbname = db_config$dbname,
    host = db_config$host,
    port = db_config$port,
    user = db_config$user,
    password = db_config$password
  )
}

