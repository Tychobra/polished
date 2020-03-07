#' configuration for global sessions
#'
#'
#' @param app_name the name of the app.
#' @param firebase_project_id the Firebase project ID.
#' @param conn the database connection
#' @param authorization_level either "app" or "all".  Use "app" to individually authorize users to this
#' app.  Use "all" to give all user that have access to any of your apps access to this app.  "all" is
#' used by our "apps_dashboard_*".
#'
#' @export
#'
global_sessions_config <- function(app_name,
                                   firebase_project_id,
                                   conn, authorization_level = "app") {

  .global_sessions$config(
    app_name = app_name,
    firebase_project_id = firebase_project_id,
    conn = conn,
    authorization_level = authorization_level
  )

}