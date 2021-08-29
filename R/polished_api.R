ua <- httr::user_agent("http://github.com/tychobra/polished")

#' Send GET Request to the Polished API
#'
#' @param resp a Polished API response
#'
#' @return an S3 object of class "polished_api_res".
#'
#' @importFrom httr http_type
#'
polished_api_res <- function(resp) {


  if (!identical(httr::http_type(resp), "application/json")) {
    stop("API did not return json", call. = FALSE)
  }

  parsed <- jsonlite::fromJSON(
    httr::content(resp, "text", encoding = "UTF-8")
  )

  if (httr::http_error(resp)) {
    cat("Polished API request failed\n")
    cat(paste0("Status Code: ", httr::status_code(resp)), "\n")
    stop(parsed$error, call. = FALSE)
  }


  structure(
    list(
      content = parsed,
      response = resp
    ),
    class = "polished_api_res"
  )
}


#' print polished_api_res
#'
#' Generic print function for \code{polished_api_res} S3 class.
#'
#' @param x an S3 object of class \code{polished_api_res}.
#' @param ... additional arguments.
#'
#' @export
#'
print.polished_api_res <- function(x, ...) {
  cat("<Polished ", x$response$url, ">\n", sep = "")
  print(x$content)
}


#' set Polished API key
#'
#' The API key is set as an R option at \code{getOption("polished")$api_key}.
#'
#' @param api_key the Polished API key
#'
#' @export
#'
#' @return a list of the newly set polished R options
#'
#' @examples
#'
#' set_api_key(api_key = "<my Polished API key>")
#'
#'
set_api_key <- function(api_key) {

  current_polished_options <- getOption("polished")

  if (is.null(current_polished_options)) {
    out <- list(
      api_key = api_key
    )
  } else {
    out <- current_polished_options
    out$api_key <- api_key
  }

  options("polished" = out)

  invisible(out)
}


set_api_url <- function(
  api_url = "https://auth-api.polished.tech/v1",
  host_api_url = "https://host-api.polished.tech/v1"
) {
  current_polished_options <- getOption("polished")

  if (is.null(current_polished_options)) {
    out <- list(
      api_url = api_url,
      host_api_url = host_api_url
    )
  } else {
    out <- current_polished_options
    out$api_url <- api_url
    out$host_api_url <- host_api_url
  }

  options("polished" = out)

  invisible(out)
}


#' Convert a list returned from the Polished API into a data frame
#'
#' In order to avoid issues with converting R data frames into JSON objects and back
#' to R data frames, we instead convert R data frames to R lists before converting
#' them to JSON to be sent via the Polished API.  This function then converts those
#' lists back into R data frames (or more precisely tibbles).
#'
#' @param api_list a list.  All elements in the list are vectors of the same length.
#'
#' @importFrom tibble as_tibble
#'
#' @return a tibble
#'
api_list_to_df <- function(api_list) {

  if (identical(length(api_list[[1]]), 0L)) {
    # if the data frame is 0 rows, then each of the list elements will be a list rather than
    # an atomic vector.  Here we convert these lists to character.
    api_list <- lapply(api_list, function(x) character(0))
  }

  tibble::as_tibble(api_list)
}



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
#' @seealso add_apps update_app delete_app
#'
#' @importFrom httr GET authenticate
#' @importFrom tibble as_tibble
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
#' @importFrom tibble as_tibble
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
#' @importFrom tibble as_tibble
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
#' @importFrom tibble as_tibble
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





