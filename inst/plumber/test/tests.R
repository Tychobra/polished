library(dplyr)
# run the docker container locally for testing
# $ docker run --rm -p 8080:8080 polished_api

url_ <- "http://localhost:8080"
#url <- "https://api.polished.tech"

test_email <- "andy.merlino@tychobra.com"

app_name_ <- "polished_hosted_example"
secret_key <- config::get(file = "test/config.yml")$api_key

# db connection for interactive queries
db_config <- config::get(file = "test/config.yml")$db
conn <- tychobratools::db_connect(db_config)




#test_app <- apps_dat %>%
#  dplyr::filter(.data$app_name == "test_app")


source("test/test_app-by-name.R", local = TRUE)


#source("test/apps.R")

source("test/test_users.R")



# GET /app-users
res <- httr::GET(
  url = paste0(url_, "/app-users"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    app_uid = app_uid
  )
)

dat <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)



# GET /invite-by-email
res <- httr::GET(
  url = paste0(url_, "/invite-by-email"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    app_uid = app_uid,
    email = test_email
  )
)

dat <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

# POST /app-users
# test that user limit works when user attempts to create a new user
res <- httr::POST(
  url = paste0(url_, "/app-users"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    email = "hi3@tychobra.com",
    app_uid = app_uid,
    is_admin = FALSE
  )
)

dat <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

res <- httr::POST(
  url = paste0(url_, "/app-users"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    email = test_email,
    app_uid = app_uid,
    is_admin = FALSE
  )
)

dat <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

# # GET /session-by-cookie
# res <- httr::GET(
#   url = paste0(url, "/session-by-cookie"),
#   httr::authenticate(
#     user = secret_key,
#     password = ""
#   ),
#   query = list(
#     # TODO: create example cookie with session for testing
#     hashed_cookie = ""
#   )
# )
#
# dat <- jsonlite::fromJSON(
#   httr::content(res, "text", encoding = "UTF-8")
# )
