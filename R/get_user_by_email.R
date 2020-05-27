#' get user by email address
#'
#' @param conn the database connection
#' @param account_uid the account uid
#' @param email the user's email address
#' @param schema the database schema
#'
#' @return a list of user info if the user is found or `NULL`
#'
#' @export
#'
#' @importFrom DBI dbGetQuery
#'
get_user_by_email <- function(conn, account_uid, email, schema = "polished") {


  user_out <- DBI::dbGetQuery(
    conn,
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
