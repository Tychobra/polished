library(pgpolished)


# function to set up database "polished" schema
db_config <- config::get()$db

db_conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = db_config$dbname,
  host = db_config$host,
  password = db_config$password,
  user = db_config$user
)

# this function will create all the tables in the polished schema.
# It will erase any data in your existing polished schema, so do not
# run this if you have data in your polished schema that you want to keep.
create_schema(db_conn)

# create the first user for your new app
create_app_user(
  db_conn,
  email = "demo@tychobra.com",
  app_name = "polished_example_01",
  is_admin = TRUE
)

# write and deploy the Firebase functions
write_firebase_functions()

system("firebase deploy --only functions")
