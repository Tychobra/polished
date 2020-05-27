
#' get invite
#'
#' @param conn the database connection
#' @param app_uid the id of the app
#' @param user_uid the user uid
#' @param schema the name of the schema
#'
#' @retun the row from the app_users table or NULL
#'
#' @importFrom DBI dbGetQuery
#'
#' @export
#'
get_invite <- function(conn, app_uid, user_uid, schema = "polished") {

  invite <- DBI::dbGetQuery(
    conn,
    paste0("SELECT * FROM ", schema, ".app_users WHERE user_uid=$1 AND app_uid=$2"),
    params = list(
      user_uid,
      app_uid
    )
  )

  if (nrow(invite) != 1) {
    return(NULL)
  }

  invite
}
