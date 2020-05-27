#' add_app
#'
#' @param conn the database connection
#' @param account_uid the account uid
#' @param app_uid the app uid
#' @param app_name the app name
#' @param schema the database schema
#'
#' @export
#'
#' @importFrom DBI dbExecute
#'
#' @return number of rows affected or an error
#'
add_app <- function(conn, account_uid, app_uid, app_name, schema = "polished") {
  DBI::dbExecute(
    conn,
    paste0("INSERT INTO ", schema, ".apps ( uid, account_uid, app_name ) VALUES
           ( $1, $2, $3 )"),
    params = list(
      app_uid,
      account_uid,
      app_name
    )
  )
}
