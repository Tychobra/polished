#' Polished API - Get App(s) User(s)
#'
#' @param app_uid an optional app uid.
#' @param user_uid an optional user uid.
#' @param email an optional user email address.
#'
#' @inheritParams get_apps
#'
#' @return an object of class \code{polished_api_res}.  The "content" of the object is a
#' tibble of app(s) with the following columns:
#' - uid
#' - app_uid
#' - user_uid
#' - is_admin
#' - created_at
#' - email
#'
#' @export
#'
#' @seealso [add_app_user()] [update_app_user()] [delete_app_user()]
#'
#' @importFrom httr GET authenticate
#'
get_app_users <- function(
  app_uid = NULL,
  user_uid = NULL,
  email = NULL,
  api_key = getOption("polished")$api_key
) {

  query_out <- list()

  query_out$app_uid <- app_uid
  query_out$user_uid <- user_uid
  query_out$email <- email


  resp <- httr::GET(
    url = paste0(getOption("polished")$api_url, "/app-users"),
    ua,
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    query = query_out
  )

  resp_out <- polished_api_res(resp)

  resp_out$content <- api_list_to_df(resp_out$content)

  resp_out
}


#' Polished API - Add a User to an App
#'
#' @param app_uid the app uid.
#' @param user_uid an optional user uid for the user to be invited to the app.
#' @param email an optional user email address.
#' @param is_admin boolean - whether or not the user is a Polished admin.
#' @param send_invite_email boolean - whether or not to send the user an invite email
#' notifying them they have been invited to access the app.
#' @param email an optional email address for the user to be invited to the app.
#'
#' @inheritParams get_apps
#'
#' @details supply either the \code{user_uid} or \code{email}. If both a provided, then
#' the \code{user_uid} will be used, and the \code{email} will be ignored.
#'
#' @export
#'
#' @seealso [get_app_users()] [update_app_user()] [delete_app_user()]
#'
#' @importFrom httr POST authenticate
#'
add_app_user <- function(
  app_uid,
  user_uid = NULL,
  email = NULL,
  is_admin = FALSE,
  send_invite_email = FALSE,
  api_key = getOption("polished")$api_key
){

  if (is.null(user_uid) && is.null(email)) {
    stop("`user_uid` and `email` cannot both be `NULL`", call. = FALSE)
  }

  if (!is.logical(is_admin)) {
    stop("`is_admin` must be `TRUE` or `FALSE`", call. = FALSE)
  }

  if (!is.logical(send_invite_email)) {
    stop("`send_invite_email` must be `TRUE` or `FALSE`", call. = FALSE)
  }

  body_out <- list(
    app_uid = app_uid
  )

  body_out$user_uid <- user_uid
  body_out$email <- email
  body_out$is_admin <- is_admin
  body_out$send_invite_email <- send_invite_email


  resp <- httr::POST(
    url = paste0(getOption("polished")$api_url, "/app-users"),
    ua,
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    body = body_out,
    encode = "json"
  )

  polished_api_res(resp)
}




#' Polished API - Update an App User
#'
#' @param app_uid the app uid to update.
#' @param user_uid the user uid to update.
#' @param is_admin boolean - whether or not the user is an admin.
#'
#' @inheritParams get_apps
#'
#'
#' @export
#'
#' @seealso [get_app_users()] [add_app_user()] [delete_app_user()]
#'
#' @importFrom httr PUT authenticate
#'
update_app_user <- function(
  app_uid,
  user_uid,
  is_admin,
  api_key = getOption("polished")$api_key
) {

  body_out <- list(
    app_uid = app_uid,
    user_uid = user_uid,
    is_admin = is_admin
  )

  resp <- httr::PUT(
    url = paste0(getOption("polished")$api_url, "/app-users"),
    ua,
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    body = body_out,
    encode = "json"
  )

  polished_api_res(resp)
}


#' Polished API - Delete an App User
#'
#' @param app_uid an app uid.
#' @param user_uid a user uid.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_apps()] [add_app()] [update_app()]
#'
#' @importFrom httr DELETE authenticate
#'
delete_app_user <- function(app_uid, user_uid, api_key = getOption("polished")$api_key) {

  query_out <- list(
    app_uid = app_uid,
    user_uid = user_uid
  )

  resp <- httr::DELETE(
    url = paste0(getOption("polished")$api_url, "/app-users"),
    ua,
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    query = query_out
  )

  polished_api_res(resp)
}
