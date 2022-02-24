#' Polished API - Get User(s)
#'
#' @param user_uid an optional user uid.
#' @param email an optional user email.
#' @param include_two_fa boolean, whether or not to include the 2FA information.
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
#' @return an object of class \code{polished_api_res}.  The `content` of the object is a
#' tibble of users(s) with the following columns:
#' - `uid`
#' - `email`
#' - `email_verified`
#' - `created_by`
#' - `created_at`
#' - `modified_by`
#' - `modified_at`
#' - `is_password_set`
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
  include_two_fa = FALSE,
  api_key = get_api_key()
) {

  query_out <- list()
  query_out$user_uid <- user_uid
  query_out$email <- email
  query_out$include_two_fa <- include_two_fa

  resp <- httr::GET(
    url = paste0(.polished$api_url, "/users"),
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
#' @param email the new user's email address.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_users()] [delete_user()]
#'
#' @importFrom httr POST authenticate
#'
add_user <- function(email, api_key = get_api_key()) {

  body_out <- list(
    email = email
  )

  resp <- httr::POST(
    url = paste0(.polished$api_url, "/users"),
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
#' @param user_uid the uid of the user to be deleted.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_users()] [add_user()]
#'
#' @importFrom httr DELETE authenticate
#'
delete_user <- function(user_uid, api_key = get_api_key()) {

  query_out <- list(
    user_uid = user_uid
  )

  resp <- httr::DELETE(
    url = paste0(.polished$api_url, "/users"),
    ua,
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    query = query_out
  )

  polished_api_res(resp)
}

#' Polished API - Update a user
#'
#' @param user_uid the uid of the user to be updated.
#' @param user_data list of data to update.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_users()] [add_user()]
#'
#' @importFrom httr PUT authenticate
#'
update_user <- function(user_uid, user_data, api_key = get_api_key()) {

  res <- httr::PUT(
    url = paste0(.polished$api_url, "/users"),
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    body = list(
      "user_uid" = user_uid,
      "dat" = user_data
    ),
    encode = "json"
  )

  polished_api_res(res)
}
