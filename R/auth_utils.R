get_signed_in_as_user = function(user_uid) {

  invite_res <- get_app_users(
    .polished$app_uid,
    user_uid
  )
  invite <- invite_res$content

  if (!identical(nrow(invite), 1L)) {
    stop("user could not be found", call. = FALSE)
  }

  roles_res <- get_user_roles(
    user_uid = user_uid
  )

  roles_df <- roles_res$content

  if (nrow(roles_df) == 0) {
    roles_out <- NA
  } else {
    roles_out <- roles_df$role_name
  }


  list(
    user_uid = user_uid,
    email = invite$email,
    is_admin = invite$is_admin,
    roles = roles_out
  )
}

sign_out = function(hashed_cookie) {

  res <- httr::POST(
    url = paste0(.polished$api_url, "/sign-out"),
    httr::authenticate(
      user = get_api_key(),
      password = ""
    ),
    body = list(
      hashed_cookie = hashed_cookie
    ),
    encode = "json"
  )

  polished_api_res(res)
}
