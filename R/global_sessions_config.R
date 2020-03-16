#' configuration for global sessions
#'
#'
#' @param conn the database connection
#' @param app_name the name of the app.
#' @param firebase_project_id the Firebase project ID.
#' @param authorization_level either "app" or "all".  Use "app" to individually authorize users to this
#' app.  Use "all" to give all user that have access to any of your apps access to this app.  "all" is
#' used by our "apps_dashboard_*".
#' @param admin_mode FALSE by default.  Set to TRUE to enter the polished Admin Panel without needing
#' to register and sign in.  This is useful during development for inviting the first users to your app.
#' Make sure to set `admin_mode` to FALSE before deploying your app.
#' @param is_invite_required TRUE by default.  Whether or not to require the user to have an
#' invite before registering/signing in
#'
#' @export
#'
global_sessions_config <- function(
  conn = NULL,
  app_name = NULL,
  firebase_project_id = NULL,
  authorization_level = "app",
  admin_mode = FALSE,
  is_invite_required = TRUE
) {

  .global_sessions$config(
    app_name = app_name,
    firebase_project_id = firebase_project_id,
    conn = conn,
    authorization_level = authorization_level,
    admin_mode = admin_mode,
    is_invite_required = is_invite_required
  )

}