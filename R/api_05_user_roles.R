#' Polished API - Get User Role(s)
#'
#' @param user_uid an optional user uid.
#' @param role_uid an optional role uid.
#'
#' @inheritParams get_apps
#'
#' @return an object of class \code{polished_api_res}.  The "content" of the object is a
#' tibble of users(s) with the following columns:
#' - role_uid
#' - role_name,
#' - user_uid,
#' - user_name,
#' - created_at
#'
#' @export
#'
#' @seealso [add_user_role()] [delete_user_role()]
#'
#' @importFrom httr GET authenticate
#'
get_user_roles <- function(
  user_uid = NULL,
  role_uid = NULL,
  api_key = get_api_key()
) {

  query_out <- list()
  query_out$user_uid <- user_uid
  query_out$role_uid <- role_uid

  resp <- httr::GET(
    url = paste0(getOption("polished")$api_url, "/user-roles"),
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


#' Polished API - Add a User Role
#'
#' @param user_uid a user uid.
#' @param role_uid a role name.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_user_roles()] [delete_user_role()]
#'
#' @importFrom httr POST authenticate
#'
add_user_role <- function(user_uid, role_uid, api_key = get_api_key()) {

  body_out <- list(
    user_uid = user_uid,
    role_uid = role_uid
  )

  resp <- httr::POST(
    url = paste0(getOption("polished")$api_url, "/user-roles"),
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




#' Polished API - Delete a User Role
#'
#' @param role_uid the role uid of the role to be deleted.
#' @param user_uid the user uid that the role should be removed from.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_user_roles()] [add_user_role()]
#'
#' @importFrom httr DELETE authenticate
#'
delete_user_role <- function(role_uid, user_uid, api_key = get_api_key()) {

  query_out <- list(
    role_uid = role_uid,
    user_uid = user_uid
  )

  resp <- httr::DELETE(
    url = paste0(getOption("polished")$api_url, "/user-roles"),
    ua,
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    query = query_out
  )

  polished_api_res(resp)
}
