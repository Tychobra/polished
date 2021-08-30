#' Polished API - Get App(s) User(s)
#'
#' @param app_uid an app uid.
#' @param email an optional email address for the user to be invited to the app.
#' @param user_uid an optional user uid for the user to be invited to the app.
#' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' so that you do not need to supply this argument with each function call.
#'
#'
#' @return an object of class \code{polished_api_res}.  The "content" of the object is a
#' tibble of app(s) with the following columns:
#' - uid
#' - app_name
#' - app_url
#' - created_at
#' - modified_at
#'
#' @export
#'
#' @seealso add_app update_app delete_app
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
#' @param app_uid an optional app uid.
#' @param app_name an optional app name.
#' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' so that you do not need to supply this argument with each function call.
#'
#' @details supply either the app uid or app name to get data about a specific app.
#'
#' @export
#'
#' @seealso get_apps update_app delete_app
#'
#' @importFrom httr GET authenticate
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

  body_out <- list()

  body_out$app_uid <- app_uid
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




#' Polished API - Update an App
#'
#' @param app_uid the app uid to update.
#' @param user_uid an optional app name.
#' @param is_admin boolean - whether or not the user is an admin.
#' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' so that you do not need to supply this argument with each function call.
#'
#'
#' @export
#'
#' @seealso get_app_users add_app_user delete_app_user
#'
#' @importFrom httr GET authenticate
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


#' Polished API - Delete an App
#'
#' @param app_uid an app uid.
#' @param user_uid a user uid.
#' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' so that you do not need to supply this argument with each function call.
#'
#' @details supply either the app uid or app name to get data about a specific app.
#'
#' @export
#'
#' @seealso get_apps add_app update_app
#'
#' @importFrom httr GET authenticate
#'
delete_app_user <- function(app_uid, user_uid, api_key = getOption("polished")$api_key) {

  body_out <- list(
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
    body = body_out,
    encode = "json"
  )

  polished_api_res(resp)
}
