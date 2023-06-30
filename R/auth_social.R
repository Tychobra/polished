


#' sign in via email password
#'
#' @param firebase_token the Firebase JWT.  This JWT is created client side
#' (in JavaScript) via `firebase.auth()`.
#' @param hashed_cookie the hashed `polished` cookie.  Used for tracking the user
#' session.  This cookie is inserted into the "polished.sessions" table if the
#' JWT is valid.
#'
#' @noRd
#'
sign_in_social <- function(
    firebase_token,
    hashed_cookie
) {

  res <- httr::POST(
    url = paste0(.polished$api_url, "/sign-in-social"),
    body = list(
      firebase_token = firebase_token,
      hashed_cookie = hashed_cookie,
      app_uid = .polished$app_uid,
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