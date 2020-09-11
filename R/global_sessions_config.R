#' Configuration for global sessions
#'
#' This is the primary function for configuring 'polished'.  It configures your app's instance of the
#' \code{Sessions} class that manages your user's 'polished' sessions.  Call this function in
#' your "global.R" file.  See \url{https://github.com/Tychobra/polished/blob/master/inst/examples/polished_example_01/global.R}
#' for a complete example.
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
#' "email", "microsoft", and/or "facebook". Defaults to \code{"email"}.
#' @param is_email_verification_required TRUE by default.  Whether or not to require the user to
#' verify their email before accessing your Shiny app.
#'
#' @export
#'
#' @importFrom httr GET authenticate content status_code
#' @importFrom jsonlite fromJSON
#'
#' @examples
#'
#' \dontrun{
#' # global.R
#'
#' global_sessions_config(
#'   app_name = "<your app name>",
#'   api_key = "<your API key>"
#' )
#'
#' }
#'
global_sessions_config <- function(
  app_name,
  api_key,
  firebase_config = NULL,
  admin_mode = FALSE,
  is_invite_required = TRUE,
  api_url = "https://api.polished.tech",
  sign_in_providers = "email",
  is_email_verification_required = TRUE
) {

  if (!(length(api_key) == 1 && is.character(api_key))) {
    stop("invalid `api_key` argument passed to `global_sessions_config()`", call. = FALSE)
  }

  if (!(length(api_url) == 1 && is.character(api_url))) {
    stop("invalid `api_url` argument passed to `global_sessions_config()`", call. = FALSE)
  }

  # get the app uid
  res <- httr::GET(
    url = paste0(api_url, "/apps"),
    query = list(
      app_name = app_name
    ),
    httr::authenticate(
      user = api_key,
      password = ""
    )
  )

  app <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  if (!identical(httr::status_code(res), 200L)) {
    stop(app, call. = FALSE)
  }

  if (length(app) == 0) {
    stop(paste0("app_name `", app_name, "` does not exist"), call. = FALSE)
  }

  # create app display name.  Creating this here and setting it in options will
  # make it easy to reuse in various locations without repeating code.
  app_name_display <- gsub("[_|-]", " ", app_name)
  app_name_display <- tools::toTitleCase(app_name_display)

  options("polished" = list(
    api_key = api_key,
    api_url = api_url,
    app_uid = app$uid,
    app_name = app_name,
    app_name_display = app_name_display
  ))

  .global_sessions$config(
    firebase_config = firebase_config,
    admin_mode = admin_mode,
    is_invite_required = is_invite_required,
    sign_in_providers = sign_in_providers,
    is_email_verification_required = is_email_verification_required
  )

}