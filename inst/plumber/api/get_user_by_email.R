#' get user by email address for the API
#'
#' This is a modification of \code{polished::get_user_by_email} to also query
#' only for users that were created by this polished.tech API account.
#'
#' @param conn_ the database connection
#' @param email the user's email address
#' @param account_uid the account that created the user
#' @param schema the database schema
#'
#' @return a list of user info if the user is found or `NULL`
#'
#' @export
#'
#' @importFrom DBI dbGetQuery
#'
get_user_by_email <- function(conn_, email, account_uid, schema = "polished") {

  user_out <- DBI::dbGetQuery(
    conn_,
    paste0("SELECT * FROM ", schema, ".users WHERE account_uid=$1 AND email=$2"),
    params = list(
      account_uid,
      email
    )
  )

  if (nrow(user_out) == 0) {
    return(NULL)
  }

  as.list(user_out)
}
