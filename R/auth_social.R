

# Number of seconds to allow for clock skew
# between our clock and the server that generates the firebase tokens.
.firebase_token_grace_period = 300



refresh_jwt_pub_key <- function() {
  google_keys_resp <- httr::GET(
    "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"#,
    #config = list(http_version = 0)
  )

  # Error if keys aren't returned successfully
  httr::stop_for_status(google_keys_resp)

  jwt_pub_key_out <- jsonlite::fromJSON(
    httr::content(google_keys_resp, "text", encoding = "UTF-8")
  )
  assign("jwt_pub_key", jwt_pub_key_out, envir = .polished)

  # Decode the expiration time of the keys from the Cache-Control header
  cache_controls <- httr::headers(google_keys_resp)[["Cache-Control"]]
  if (!is.null(cache_controls)) {
    cache_control_elems <- strsplit(cache_controls, ",")[[1]]
    split_equals <- strsplit(cache_control_elems, "=")
    for (elem in split_equals) {

      if (length(elem) == 2 && trimws(elem[1]) == "max-age") {
        max_age <- as.numeric(elem[2])

        assign("jwt_pub_key_expires", as.numeric(Sys.time()) + max_age, envir = .polished)
        break
      }

    }
  }
}

verify_firebase_token = function(firebase_token) {
  # Google sends us 2 public keys to authenticate the JWT.  Sometimes the correct
  # key is the first one, and sometimes it is the second.  I do not know how
  # to tell which key is the right one to use, so we try them both for now.
  decoded_jwt <- NULL
  for (key in .polished$jwt_pub_key) {
    # If a key isn't the right one for the Firebase token, then we get an error.
    # Ignore the errors and just don't set decoded_token if there's
    # an error. When we're done, we'll look at the the decoded_token
    # to see if we found a valid key.
    try({
      decoded_jwt <- jose::jwt_decode_sig(firebase_token, key)
      break
    }, silent = TRUE)
  }

  if (is.null(decoded_jwt)) {
    stop("[polished] error decoding JWT", call. = FALSE)
  }

  curr_time <- as.numeric(Sys.time())
  # Verify the ID token
  # https://firebase.google.com/docs/auth/admin/verify-id-tokens
  if (!(as.numeric(decoded_jwt$exp) + .firebase_token_grace_period > curr_time &&
        as.numeric(decoded_jwt$iat) < curr_time + .firebase_token_grace_period &&
        as.numeric(decoded_jwt$auth_time) < curr_time + .firebase_token_grace_period &&
        decoded_jwt$aud == .polished$firebase_config$projectId &&
        decoded_jwt$iss == paste0("https://securetoken.google.com/", .polished$firebase_config$projectId) &&
        nchar(decoded_jwt$sub) > 0)) {

    stop("[polished] error verifying JWT", call. = FALSE)
  }

  decoded_jwt
}

#' verify the users Firebase JWT and store the session
#'
#' @param firebase_token the Firebase JWT.  This JWT is created client side
#' (in JavaScript) via `firebase.auth()`.
#' @param hashed_cookie the hashed `polished` cookie.  Used for tracking the user
#' session.  This cookie is inserted into the "polished.sessions" table if the
#' JWT is valid.
#'
#' @importFrom uuid UUIDgenerate
#'
#' @return NULL if sign in fails. If sign in is successful, a list containing the following:
#' * email
#' * email_verified
#' * is_admin
#' * user_uid
#' * hashed_cookie
#' * session_uid
#' @md
#'
#'
sign_in_social = function(
  firebase_token,
  hashed_cookie
) {

  decoded_jwt <- NULL


  # check if the jwt public key has expired or if it is about to expire.  If it
  # is about to expire, go ahead and refresh to be safe.
  if (as.numeric(Sys.time()) + .firebase_token_grace_period > .polished$jwt_pub_key_expires) {
    refresh_jwt_pub_key()
  }

  decoded_jwt <- verify_firebase_token(firebase_token)

  new_session <- NULL

  if (!is.null(decoded_jwt)) {

    hold_session_email <- decoded_jwt$email

    invite <- get_app_users(
      app_uid = .polished$app_uid,
      email = hold_session_email,
    )$content

    if (isFALSE(.polished$is_invite_required) && identical(nrow(invite), 0L)) {
      # if invite is not required, and this is the first time that the user is signing in,
      # then create the App User in the `app_users` table
      add_app_user_res <- add_app_user(
        app_uid = .polished$app_uid,
        email = hold_session_email,
        is_admin = FALSE
      )


      invite <- get_app_users(
        app_uid = .polished$app_uid,
        email = hold_session_email
      )$content
    }

    if (identical(nrow(invite), 0L)) {
      stop("[polished] error checking user invite", call. = FALSE)
    }


    new_session <- list(
      is_admin = invite$is_admin,
      user_uid = invite$user_uid,
      hashed_cookie = hashed_cookie,
      session_uid = uuid::UUIDgenerate()
    )

    # add the session to the 'sessions' table
    add_session(
      app_uid = .polished$app_uid,
      session_data = new_session
    )
  }

  return(new_session)
}
