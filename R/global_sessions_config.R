#' configuration for global sessions
#'
#'
#' @param app_name the name of the app.
#' @param api_key the API key. Either from polished.tech or your on premise polished API
#' deployment.
#' @param firebase_config a list containing your Firebase project configuration.  This list should have the
#' following named elements:
#' \itemize{
#'   \item{apiKey}
#'   \item{authDomain}
#'   \item{projectId}
#' }
#' @param admin_mode FALSE by default.  Set to TRUE to enter the polished Admin Panel without needing
#' to register and sign in.  This is useful during development for inviting the first users to your app.
#' Make sure to set `admin_mode` to FALSE before deploying your app.
#' @param is_invite_required TRUE by default.  Whether or not to require the user to have an
#' invite before registering/signing in
#' @param api_url the API url.  Defaults to "https://api.polished.tech".
#' @param sign_in_providers the sign in providers to enable.  Valid values are "google"
#' "email", "microsoft", and/or "facebook". Defaults to \code{c("google", "email")}.
#'
#' @export
#'
global_sessions_config <- function(
  app_name,
  api_key,
  firebase_config = NULL,
  admin_mode = FALSE,
  is_invite_required = TRUE,
  api_url = "https://api.polished.tech",
  sign_in_providers = c(
    "google",
    "email"
  )
) {

  .global_sessions$config(
    app_name = app_name,
    firebase_config = firebase_config,
    admin_mode = admin_mode,
    is_invite_required = is_invite_required,
    api_key = api_key,
    api_url = api_url,
    sign_in_providers = sign_in_providers
  )

}