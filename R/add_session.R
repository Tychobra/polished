#' add session to the "sessions" table
#'
#' @param conn_ the database connection
#' @param session list containing session data with the following elements:
#' - session_uid
#' - user_uid
#' - email
#' - email_verified
#' - hashed_cookie
#' @param app_uid the id of the apps
#' @param schema the database schema
#'
#' @export
#'
#' @importFrom DBI dbExecute
#'
#'
#'
add_session <- function(conn_, session, app_uid, schema = "polished") {
  DBI::dbExecute(
    conn_,
    paste0('INSERT INTO ', schema, '.sessions (uid, user_uid, email, email_verified,
    hashed_cookie, app_uid) VALUES ($1, $2, $3, $4, $5, $6)'),
    list(
      session$session_uid,
      session$user_uid,
      session$email,
      session$email_verified,
      session$hashed_cookie,
      app_uid
    )
  )
}
