sign_in_email = function(email, password, hashed_cookie) {

  res <- httr::POST(
    url = paste0(.polished$api_url, "/sign-in-email"),
    body = list(
      app_uid = .polished$app_uid,
      email = email,
      password = password,
      hashed_cookie = hashed_cookie,
      is_invite_required = .polished$is_invite_required
    ),
    encode = "json",
    httr::authenticate(
      user = get_api_key(),
      password = ""
    )
  )

  session_out <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  if (!identical(httr::status_code(res), 200L)) {

    if (identical(session_out$error, "Password reset required")) {

      # send a password reset email and stop
      res2 <- httr::POST(
        url = paste0(.polished$api_url, "/send-password-reset-email"),
        body = list(
          email = email,
          app_uid = .polished$app_uid,
          is_invite_required = .polished$is_invite_required
        ),
        httr::authenticate(
          user = get_api_key(),
          password = ""
        ),
        encode = "json"
      )

      res2_content <- jsonlite::fromJSON(
        httr::content(res2, "text", encoding = "UTF-8")
      )

      if (!identical(httr::status_code(res2), 200L)) {
        stop(res2_content$error, call. = FALSE)
      }

      return(list(
        message = "Password reset email sent"
      ))

    } else {
      stop(session_out$error, call. = FALSE)
    }
  }

  session_out
}

register_email = function(email, password, hashed_cookie) {

  res <- httr::POST(
    url = paste0(.polished$api_url, "/register-email"),
    httr::authenticate(
      user = get_api_key(),
      password = ""
    ),
    body = list(
      app_uid = .polished$app_uid,
      email = email,
      password = password,
      hashed_cookie = hashed_cookie,
      is_invite_required = .polished$is_invite_required,
      is_email_verification_required = .polished$is_email_verification_required
    ),
    encode = "json"
  )

  session_out <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  if (!identical(httr::status_code(res), 200L)) {
    stop(session_out$error, call. = FALSE)
  }

  session_out
}
