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
    app_name = app_name_
  ),
  encode = "json"
)

res <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

# check that the new user does in fact exist
new_test_app <- conn %>%
  tbl(in_schema(schema, "apps")) %>%
  filter(app_name == .env$app_name_) %>%
  collect()

status_out <- httr::status_code(res)

# TRUE: expect status code == 200
if (status_out == 200) print("PASS") else stop("FAIL")
if (nrow(new_test_app) == 1) print("PASS") else stop("FAIL")

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

#test_app <- apps_dat %>%
#  dplyr::filter(.data$app_name == app_name_)

#if (nrow(new_test_app) == 1) print("PASS") else stop("FAIL")

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


# recreate an app for testing next enpoints
res <- httr::POST(
  paste0(url_, "/apps"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    app_name = app_name_
  ),
  encode = "json"
)

res_status <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)
