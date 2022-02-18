sign_in_email = function(email, password, hashed_cookie) {

  res <- httr::POST(
    url = paste0(getOption("polished")$api_url, "/sign-in-email"),
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
        url = paste0(getOption("polished")$api_url, "/send-password-reset-email"),
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
    url = paste0(getOption("polished")$api_url, "/register-email"),
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

refresh_email_verification = function(session_uid, firebase_token) {

  email_verified <- NULL


  # check if the jwt public key has expired.  Add an extra minute to the
  # current time for padding before checking if the key has expired.
  if (Sys.time() + .firebase_token_grace_period > .jwt_pub_key_expires) {
    refresh_jwt_pub_key()
  }

  decoded_jwt <- verify_firebase_token(firebase_token)

  if (!is.null(decoded_jwt)) {
    email_verified <- decoded_jwt$email_verified
  }


  if (is.null(email_verified)) {
    stop("email verification user not found", call. = FALSE)
  }

  out <- update_session(
    session_uid,
    dat = list(
      email_verified = email_verified
    )
  )


  out
}