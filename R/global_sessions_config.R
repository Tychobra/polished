#' configuration for global sessions
#'
#'
#' @param conn the database connection
#' @param app_name the name of the app.
#' @param firebase_config a list containing your Firebase project configuration.  This list should have the
#' following named elements:
#' \itemize{
#'   \item{apiKey}
#'   \item{authDomain}
#'   \item{projectId}
#' }
#'
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
  firebase_config = NULL,
  admin_mode = FALSE,
  is_invite_required = TRUE
) {

  .global_sessions$config(
    app_name = app_name,
    firebase_config = firebase_config,
    conn = conn,
    admin_mode = admin_mode,
    is_invite_required = is_invite_required
  )

}