#' Polished API - Get Role(s)
#'
#' @param role_uid an optional role uid.
#'
#' @inheritParams get_apps
#'
#' @return an object of class \code{polished_api_res}.  The "content" of the object is a
#' tibble of users(s) with the following columns:
#' - uid
#' - role_name
#' - created_at
#'
#' @export
#'
#' @seealso [add_role()] [delete_role()]
#'
#' @importFrom httr GET authenticate
#'
get_roles <- function(
  role_uid = NULL,
  api_key = get_api_key()
) {

  query_out <- list()
  query_out$role_uid <- role_uid

  resp <- httr::GET(
    url = paste0(getOption("polished")$api_url, "/roles"),
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


#' Polished API - Add a Role
#'
#' @param role_name a role name.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_roles()] [delete_role()]
#'
#' @importFrom httr GET authenticate
#'
add_role <- function(role_name, api_key = get_api_key()) {

  body_out <- list(
    role_name = role_name
  )

  resp <- httr::POST(
    url = paste0(getOption("polished")$api_url, "/roles"),
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




#' Polished API - Delete a Role
#'
#' @param role_uid the role uid of the role to be deleted.
#'
#' @inheritParams get_apps
#'
#' @export
#'
#' @seealso [get_roles()] [add_role()]
#'
#' @importFrom httr DELETE authenticate
#'
delete_role <- function(role_uid, api_key = get_api_key()) {

  query_out <- list(
    role_uid = role_uid
  )

  resp <- httr::DELETE(
    url = paste0(getOption("polished")$api_url, "/roles"),
    ua,
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    query = query_out
  )

  polished_api_res(resp)
}
