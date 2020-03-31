
#' get invite
#'
#' @param conn_ the database connection
#' @param app_name the app name
#' @param user_uid the user uid
#' @param schema the name of the schema
#'
#' @retun the row from the app_users table or NULL
#'
#' @importFrom DBI dbGetQuery
#'
#' @export
#'
get_invite <- function(conn_, app_name, user_uid, schema = "polished") {

  invite <- DBI::dbGetQuery(
    conn_,
    paste0("SELECT * FROM ", schema, ".app_users WHERE user_uid=$1 AND app_name=$2"),
    params = list(
      user_uid,
      app_name
    )
  )

  if (nrow(invite) != 1) {
    return(NULL)
  }

  invite
}
