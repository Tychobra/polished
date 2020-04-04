
#' update app user
#'
#' Update a user authorized to access and app.
#'
#' @param conn the database connection
#' @param user_uid the uid for the user to update
#' @param app_uid the app id
#' @param is_admin boolean whether or not the user is and admin
#' @param modified_by the uid of the user making the edit
#' @param schema the database schema
#'
#' @export
#'
#' @importFrom DBI dbExecute
#' @importFrom tychobratools time_now_utc
#'
update_app_user <- function(conn, user_uid, app_uid, is_admin, modified_by, schema = "polished") {
  DBI::dbExecute(
    conn,
    paste0("UPDATE ", schema, ".app_users SET is_admin=$1, modified_by=$2, modified_at=$3 WHERE user_uid=$4 AND app_uid=$5"),
    params = list(
      is_admin,                   # is_admin
      modified_by,                   # modified_by
      tychobratools::time_now_utc(),  # modified_at
      user_uid,             # user_uid
      app_uid       # app_name
    )
  )
}
