#' Polished API - Get Sessions
#'
#' This can currently only be used to get a single session
#'
#' @param app_uid the app uid
#' @param hashed_cookie the hashed cookie
#'
#' @inheritParams get_apps
#'
#' @return either \code{NULL} or object of class \code{polished_api_res}.  The "content" of the object is a
#' list with the following elements:
#' - user_uid
#' - email
#' - email_verified
#' - is_admin
#' - hashed_cookie
#' - session_uid
#' - signed_in_as
#' - roles
#'
#' @noRd
#'
#' @importFrom httr GET authenticate
#'
get_sessions = function(app_uid, hashed_cookie, api_key = get_api_key()) {

  res <- httr::GET(
    url = paste0(getOption("polished")$api_url, "/sessions"),
    query = list(
      hashed_cookie = hashed_cookie,
      app_uid = app_uid
    ),
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    encode = "json"
  )

  out <- polished_api_res(res)

  if (length(out$content) == 0) {
    out$content <- NULL
  }

  out
}


#' Polished API - Add a session
#'
#' @param app_uid the app uid.
#' @param session_data list of data to include in the session.
#'
#' @inheritParams get_apps
#'
#'
#' @importFrom httr POST authenticate
#'
add_session <- function(app_uid, session_data, api_key = get_api_key()) {

  # add session to "sessions" table via the API
  res <- httr::POST(
    url = paste0(getOption("polished")$api_url, "/sessions"),
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    body = list(
      data = session_data,
      app_uid = app_uid
    ),
    encode = "json"
  )

  polished_api_res(res)
}




#' Polished API - Update a session
#'
#' @param session_uid the role uid of the role to be deleted.
#' @param user_uid the user uid that the role should be removed from.
#'
#' @inheritParams get_apps
#'
#'
#' @seealso [get_user_roles()] [add_user_role()]
#'
#' @importFrom httr PUT authenticate
#'
update_session <- function(session_uid, dat, api_key = get_api_key()) {

  res <- httr::PUT(
    url = paste0(getOption("polished")$api_url, "/sessions"),
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    body = list(
      "session_uid" = session_uid,
      "dat" = dat
    ),
    encode = "json"
  )

  polished_api_res(res)
}
