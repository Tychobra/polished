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

create_secret <- function() {
  stringi::stri_rand_strings(1, 34, pattern = "[A-Za-z0-9]")
}

create_account <- function(conn, email, hosting_secret) {

  api_key <- create_secret()
  api_key_hashed <- digest::digest(api_key)

  DBI::dbExecute(
    conn,
    "INSERT INTO polished.accounts (email, polished_key, hashed_polished_key) VALUES
    ($1, PGP_SYM_ENCRYPT($2, $3), $4)",
    list(
      email,
      api_key,
      hosting_secret,
      api_key_hashed
    )
  )

  api_key
}

hosting_secret <- create_secret()

# copy the hosting secret into your api config.yml.  This secret will be used directly by the API
# server

create_account(
  db_conn,
  email = "andy.merlino@tychobra.com",
  hosting_secret = hosting_secret
)

account_uid <- DBI::dbGetQuery(db_conn, "SELECT uid FROM polished.accounts")$uid

add_app(
   db_conn,
   account_uid = account_uid,
   app_uid = uuid::UUIDgenerate(),
   app_name = "polished_example_01"
)
