
#' add_user
#'
#' @param conn the database connection
#' @param email the email address of the user to be added
#' @param created_by the uid of the user that created this new user
#' @param schema the database schema
#'
#' @importFrom DBI dbExecute
#' @importFrom uuid UUIDgenerate
#'
#' @return the uid of the newly created user or NULL if the user already exists
#'
#' @export
#'
#'
add_user <- function(conn, email, created_by, schema = "polished") {

  user_uid_out <- uuid::UUIDgenerate()

  n_row <- DBI::dbExecute(
    conn,
    paste0("INSERT INTO ", schema, ".users ( uid, email, created_by, modified_by ) VALUES ( $1, $2, $3, $4 ) ON CONFLICT DO NOTHING"),
    params = list(
      user_uid_out,
      email,
      created_by,
      created_by
    )
  )

  if (n_row == 1) user_uid_out else NULL
}
