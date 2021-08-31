#' Polished API - Get User(s)
#'
#' @param user_uid an optional user uid.
#' @param email an optional user email.
#'
#' @inheritParams get_apps
#'
#' @details If both the \code{user_uid} and \code{email} are \code{NULL}, then all the
#' users in your account will be returned.  If either \code{user_uid} or \code{email} are not
#' \code{NULL}, then a single user will be returned (assuming the user exists).  If both the
#' \code{user_uid} and \code{email} are provided, then the \code{user_uid} will be used,
#' and the \code{email} will be ignored.  If the user does not exists, a zero row tibble
#' will be returned.
#'
#' @return an object of class \code{polished_api_res}.  The "content" of the object is a
#' tibble of users(s) with the following columns:
#' - uid
#' - email
#' - email_verified
#' - created_by
#' - created_at
#' - modified_by
#' - modified_at
#' - is_password_set
#'
#' @export
#'
#' @seealso [add_user()] [delete_user()]
#'
#' @importFrom httr GET authenticate
#'
get_users <- function(
  user_uid = NULL,
  email = NULL,
  api_key = getOption("polished")$api_key
) {

  query_out <- list()
  query_out$user_uid <- user_uid
  query_out$email <- email

  resp <- httr::GET(
    url = paste0(getOption("polished")$api_url, "/users"),
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


#' Polished API - Add a User
#'
#' @param email an email address.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_users()] [delete_user()]
#'
#' @importFrom httr POST authenticate
#'
add_user <- function(email, api_key = getOption("polished")$api_key) {

  body_out <- list(
    email = email
  )

  resp <- httr::POST(
    url = paste0(getOption("polished")$api_url, "/users"),
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




#' Polished API - Delete a User
#'
#' @param user_uid the user uid of the user to be deleted.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_users()] [add_user()]
#'
#' @importFrom httr DELETE authenticate
#'
delete_user <- function(user_uid, api_key = getOption("polished")$api_key) {

  body_out <- list(
    user_uid = user_uid
  )

  resp <- httr::DELETE(
    url = paste0(getOption("polished")$api_url, "/users"),
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
