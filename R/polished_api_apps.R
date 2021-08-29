#' Polished API - Get App(s)
#'
#' @param app_uid an optional app uid.
#' @param app_name an optional app name.
#' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' so that you do not need to supply this argument with each function call.
#'
#' @details If both the \code{app_uid} and \code{app_name} are \code{NULL}, then all the
#' apps in your account will be returned.  If either \code{app_uid} or \code{app_name} are not
#' \code{NULL}, then a single app will be returned (assuming the app exists).  If both the
#' \code{app_uid} and \code{app_name} are provided, then the \code{app_uid} will be used,
#' and the \code{app_name} will be ignored.  If the app does not exists, a zero row tibble
#' will be returned.
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
get_apps <- function(
  app_uid = NULL,
  app_name = NULL,
  api_key = getOption("polished")$api_key
) {

  query_out <- list(
    app_uid = app_uid,
    app_name = app_name
  )

  resp <- httr::GET(
    url = paste0(getOption("polished")$api_url, "/apps"),
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


#' Polished API - Add an App
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
add_app <- function(app_name = NULL, app_url = NULL, api_key = getOption("polished")$api_key) {

  body_out <- list(
    app_name = app_name,
    app_url = app_url
  )

  resp <- httr::POST(
    url = paste0(getOption("polished")$api_url, "/apps"),
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
#' @param app_name an optional app name.
#' @param app_url an optional app url.
#' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' so that you do not need to supply this argument with each function call.
#'
#' @details supply either the app uid or app name to get data about a specific app.
#'
#' @export
#'
#' @seealso get_apps add_app delete_app
#'
#' @importFrom httr GET authenticate
#'
update_app <- function(app_uid = NULL, app_name = NULL, app_url = NULL, api_key = getOption("polished")$api_key) {

  body_out <- list(
    app_uid = app_uid
  )

  if (is.null(app_name) && is.null(app_url)) {
    stop("one of either `app_name` or `app_url` must not be NULL", call. = FALSE)
  } else {
    body_out$app_name <- app_name
    body_out$app_url <- app_url
  }

  resp <- httr::PUT(
    url = paste0(getOption("polished")$api_url, "/apps"),
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
#' @param app_uid an optional app uid.
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
delete_app <- function(app_uid = NULL, api_key = getOption("polished")$api_key) {

  body_out <- list(
    app_uid = app_uid
  )

  resp <- httr::DELETE(
    url = paste0(getOption("polished")$api_url, "/apps"),
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
