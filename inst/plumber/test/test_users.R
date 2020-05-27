#####
#
# /users
#
#####
# create a user
res <- httr::POST(
  paste0(url_, "/users"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    email = "test_user@tychobra.com"
  ),
  encode = "json"
)
res_status <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

# check that the new user does in fact exist
new_test_user <- conn %>%
  tbl("users") %>%
  filter(email == "test_user@tychobra.com") %>%
  collect()

if (nrow(new_test_user) == 1) print("PASS") else stop("FAIL")

# delete the newly created app
res <- httr::DELETE(
  paste0(url_, "/users"),
  httr::authenticate(
    user = secret_key,
    password = ""
  ),
  query = list(
    user_uid = new_test_user$uid
  ),
  encode = "json"
)

res_status <- jsonlite::fromJSON(
  httr::content(res, "text", encoding = "UTF-8")
)

# check that the new user does in fact exist
new_test_user <- conn %>%
  tbl("users") %>%
  filter(email == "test_user@tychobra.com") %>%
  collect()

if (nrow(new_test_user) == 0) print("PASS") else stop("FAIL")
