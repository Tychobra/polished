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

polished::create_schema(db_conn)

# add the first user to your first app
# I always add myself first using this function, and then I add other additional users via
# the "Polished Admin > User Access" page

polished::create_app_user(
  db_conn,
  app_name = "polished_example_01",
  email = "demo@tychobra.com",
  is_admin = TRUE
)

polished::create_app_user(
  db_conn,
  app_name = "custom_sign_in",
  email = "demo@tychobra.com",
  is_admin = TRUE
)
