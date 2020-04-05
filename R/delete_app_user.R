#' delete app user
#'
#' Delete an app user from the "app_users" table
#'
#' @param conn the database connection
#' @param app_uid_ the app uid
#' @param user_uid the user uid
#' @param schema the database schema
#'
#' @export
#'
#' @importFrom DBI dbExecute
#'
delete_app_user <- function(conn, app_uid_, user_uid, schema = "polished") {

  DBI::dbExecute(
    conn,
    paste0("DELETE FROM ", schema, ".app_users WHERE user_uid=$1 AND app_uid=$2"),
    params = list(
      user_uid,
      app_uid_
    )
  )

}
