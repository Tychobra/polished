

#' sign_out
#'
#' @param conn the database connection
#' @param hashed_cookie the user's hashed browser cookie
#' @param session_uid the user's session uid
#' @param schema the database schema
#'
#' @importFrom DBI dbExecute
#'
#' @export
#'
sign_out <- function(conn, hashed_cookie, session_uid, schema = "polished") {

  # sign the user out of all sessions with this cookie.  This will cause the user
  # to be signed out of all apps that they are signed into in the browser that they
  # have open
  DBI::dbExecute(
    conn,
    paste0("UPDATE ", schema, ".sessions SET is_active=$1, is_signed_in=$2 WHERE hashed_cookie=$3"),
    list(
      FALSE,
      FALSE,
      hashed_cookie
    )
  )

  # record the sign out action in the "session_actions" table
  DBI::dbExecute(
    conn,
    paste0("INSERT INTO ", schema, ".session_actions (uid, session_uid, action) VALUES ($1, $2, $3)"),
    list(
      uuid::UUIDgenerate(),
      session_uid,
      'sign_out'
    )
  )
}