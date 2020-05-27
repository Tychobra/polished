#### ------------------
#
# /apps
#
#### ------------------

# create an app
res <- httr::POST(
  paste0(url_, "/apps"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    app_uid = uuid::UUIDgenerate(),
    app_name = "test_app"
  ),
  encode = "json"
)

res_status <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

# get all apps
res <- httr::GET(
  paste0(url_, "/apps"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  encode = "json"
)

apps_dat <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

test_app <- apps_dat %>%
  dplyr::filter(.data$app_name == "test_app")

# delete the newly created app
res <- httr::DELETE(
  paste0(url_, "/apps"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    app_uid = test_app$uid
  ),
  encode = "json"
)

res_status <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

test_app <- apps_dat %>%
  dplyr::filter(.data$app_name == "test_app")
