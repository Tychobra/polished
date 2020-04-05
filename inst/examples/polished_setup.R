library(polished)

db_config <- config::get(file = "polished_example_01/config.yml")$db

# connect to your PostgreSQL database
db_conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = db_config$dbname,
  host = db_config$host,
  user = db_config$user,
  password = db_config$password
)

create_schema(db_conn)
