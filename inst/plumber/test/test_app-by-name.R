#### ------------------
#
# /apps
#
#### ------------------


# GET /app-by-name
res <- httr::GET(
  paste0(url_, "/app-by-name"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    app_name = app_name_
  ),
  encode = "json"
)

app_dat <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

app_uid <- app_dat$app_uid

status_out <- httr::status_code(res)

# TRUE: expect status code == 200
if (status_out == 200) print("PASS") else stop("FAIL")
# TRUE: expect app uid == "a27c1a89-0363-4e58-b6c1-7f1b88d19e31"
if (app_uid == "a27c1a89-0363-4e58-b6c1-7f1b88d19e31") print("PASS") else stop("FAIL")



res <- httr::GET(
  paste0(url_, "/app-by-name"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    app_name = "non existant app name"
  ),
  encode = "json"
)

app_dat <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

err_message <- app_dat$error
status_out <- httr::status_code(res)
# TRUE: expect status code == 404
if (status_out == 404) print("PASS") else stop("FAIL")
# TRUE: expect the following error message
if (err_message == "`global_sessions_config()` `app_name` not found") print("PASS") else stop("FAIL")
