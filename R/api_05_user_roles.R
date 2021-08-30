#' Polished API - Get User Role(s)
#'
#' @param user_uid an optional user uid.
#' @param role_uid an optional role uid.
#' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' so that you do not need to supply this argument with each function call.
#'
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
#' @seealso add_role delete_role
#'
#' @importFrom httr GET authenticate
#'
get_user_roles <- function(
  user_uid = NULL,
  role_uid = NULL,
  api_key = getOption("polished")$api_key
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
#' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' so that you do not need to supply this argument with each function call.
#'
#'
#' @export
#'
#' @seealso get_roles delete_role
#'
#' @importFrom httr GET authenticate
#'
add_user_role <- function(user_uid, role_uid, api_key = getOption("polished")$api_key) {

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




#' #' Polished API - Delete a User Role
#' #'
#' #' @param role_uid the role uid of the role to be deleted.
#' #' @param api_key your Polished API key.  Set your polished api key using \code{\link{set_api_key()}}
#' #' so that you do not need to supply this argument with each function call.
#' #'
#' #'
#' #' @export
#' #'
#' #' @seealso get_apps add_app update_app
#' #'
#' #' @importFrom httr GET authenticate
#' #'
#' delete_user_role <- function(role_uid, api_key = getOption("polished")$api_key) {
#'
#'   body_out <- list(
#'     role_uid = role_uid
#'   )
#'
#'   resp <- httr::DELETE(
#'     url = paste0(getOption("polished")$api_url, "/user-roles"),
#'     ua,
#'     httr::authenticate(
#'       user = api_key,
#'       password = ""
#'     ),
#'     body = body_out,
#'     encode = "json"
#'   )
#'
#'   polished_api_res(resp)
#' }
