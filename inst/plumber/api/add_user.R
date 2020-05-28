#' add_user
#'
#' @param conn the database connection
#' @param account_uid the account uid
#' @param email the email address of the user to be added
#' @param created_by the uid of the user that created this new user
#' @param modified_by the uid of the user that last modified this user
#' @param schema the database schema
#' @param unique_user_limit a limit for the number of unique users allowed for the
#' account.  This is used with the polished.tech API.  Defaults to \code{NULL}.
#'
#' @importFrom DBI dbExecute
#' @importFrom uuid UUIDgenerate
#'
#' @return the uid of the newly created user or NULL if the user already exists
#'
#' @export
#'
#'
add_user <- function(conn, account_uid, email, created_by, modified_by = NULL, schema = "polished", unique_user_limit = NULL) {


  if (!is.null(unique_user_limit)) {

    # check if the unique user limit has been exceeded
    n_users <- DBI::dbGetQuery(
      conn,
      paste0("SELECT COUNT(uid) FROM ", schema, ".users WHERE created_by=$1"),
      params = list(
        created_by
      )
    )$count

    if (n_users >= unique_user_limit) {
      stop("unique user limit exceeded", call. = FALSE)
    }
  }


  if (is.null(modified_by)) modified_by <- created_by

  user_uid_out <- uuid::UUIDgenerate()

  n_row <- DBI::dbExecute(
    conn,
    paste0(
      "INSERT INTO ", schema, ".users (
        uid,
        account_uid,
        email,
        created_by,
        modified_by
      ) VALUES ( $1, $2, $3, $4, $5 ) ON CONFLICT DO NOTHING"
    ),
    params = list(
      user_uid_out,
      account_uid,
      email,
      created_by,
      modified_by
    )
  )



  if (n_row == 1) {
    # log message of successful user add for API
    write_log(type = "info", message = "user invite sent")

    out <- user_uid_out
  } else {
    out <- NULL
  }

  out
}
