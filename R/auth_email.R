

#' @noRd
create_cookie <- function(is_hashed = TRUE) {
  out <- uuid::UUIDgenerate()

  if (isTRUE(is_hashed)) {
    out <- digest::digest(out)
  }

  out
}


#' sign in via email password
#'
#' @param email the user's email address
#' @param password the user's password
#' @param hashed_cookie the hashed cookie
#'
#' @noRd
#'
sign_in_email <- function(
  email,
  password,
  hashed_cookie
) {

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

  polished_api_res(res)
}

#' @noRd
register_email <- function(email, password, hashed_cookie) {

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

  polished_api_res(res)
}
