
#' add_user
#'
#' @param conn_ the database connection
#' @param email the email address of the user to be added
#' @param created_by the uid of the user that created this new user
#'
#' @importFrom DBI dbExecute
#' @importFrom uuid UUIDgenerate
#'
#' @export
#'
#'
add_user <- function(conn_, email, created_by) {

  user_uid_out <- uuid::UUIDgenerate()

  DBI::dbExecute(
    conn_,
    "INSERT INTO users ( uid, email, created_by, modified_by ) VALUES ( $1, $2, $3, $4 )",
    params = list(
      user_uid_out,
      email_,
      created_by,
      created_by
    )
  )
}
