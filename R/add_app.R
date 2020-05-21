#' add_app
#'
#' @param conn the database connection
#' @param app_uid the app uid
#' @param app_name the app name
#' @param created_by user_uid for user who created the app
#' @param modified_by user_uid for the user who modified the app
#' @param schema the database schema
#'
#' @export
#'
#' @importFrom DBI dbExecute
#'
#' @return number of rows affected or an error
#'
add_app <- function(conn, app_uid, app_name, created_by, modified_by, schema = "polished") {
  DBI::dbExecute(
    conn,
    paste0("INSERT INTO ", schema, ".apps ( uid, app_name, created_by, modified_by ) VALUES ( $1, $2, $3, $4 )"),
    params = list(
      app_uid,
      app_uid,
      created_by,
      created_by
    )
  )
}
