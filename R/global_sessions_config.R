#' Configuration for global sessions
#'
#' This is the primary function for configuring \code{polished}.  It configures your app's instance of the
#' \code{Sessions} class that manages your user's \code{polished} sessions.  Call this function in
#' your \code{global.R} file.  See \url{https://github.com/Tychobra/polished/blob/master/inst/examples/polished_example_01/global.R}
#' for a complete example.
#'
#' @param app_name the name of the app.
#' @param api_key the API key. Either from \url{https://polished.tech} or your on premise \code{polished} API
#' deployment.
#' @param firebase_config a list containing your Firebase project configuration.  This list should have the
#' following named elements:
#' \itemize{
#'   \item{\code{apiKey}}
#'   \item{\code{authDomain}}
#'   \item{\code{projectId}}
#' }
#' @param admin_mode \code{FALSE} by default.  Set to \code{TRUE} to enter the \code{polished} Admin Panel without needing
#' to register and sign in.  This is useful during development for inviting the first users to your app.
#' Make sure to set \code{admin_mode = FALSE} before deploying your app.
#' @param is_invite_required \code{TRUE} by default.  Whether or not to require the user to have an
#' invite before registering/signing in
#' @param api_url the API url.  Defaults to \code{"https://api.polished.tech"}.
#' @param sign_in_providers the sign in providers to enable.  Valid values are \code{"google"}
#' \code{"email"}, \code{"microsoft"}, and/or \code{"facebook"}. Defaults to \code{"email"}.
#' @param is_email_verification_required \code{TRUE} by default.  Whether or not to require the user to
#' verify their email before accessing your Shiny app.
#' @param is_auth_required \code{TRUE} by default.  Whether or not to require users to be signed
#' in to access the app.  It can be useful to set this argument to \code{FALSE} if you want to
#' allow user to do certain actions (such as viewing charts and tables) without signing in,
#' and only require users to sign in if they want to save data to your database.
#' @param sentry_dsn either \code{NULL}, the default, or a list of 2 in the following format:
#'  - "r" : the Sentry DSN for your R server code
#'  - "js" : the Sentry DSN for your JS cleint code
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
  is_email_verification_required = TRUE,
  is_auth_required = TRUE,
  sentry_dsn = NULL
) {

  if (!(length(api_key) == 1 && is.character(api_key))) {
    stop("invalid `api_key` argument passed to `global_sessions_config()`", call. = FALSE)
  }

  if (!(length(api_url) == 1 && is.character(api_url))) {
    stop("invalid `api_url` argument passed to `global_sessions_config()`", call. = FALSE)
  }

  if (!(is.null(sentry_dsn) || (is.list(sentry_dsn) && all( names(sentry_dsn) %in% c("r", "js")) ) ) ) {
    stop("invalid `sentry_dsn` argument passed to `global_sessions_config()`", call. = FALSE)
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
    app_name_display = app_name_display,
    sentry_dsn = sentry_dsn
  ))

  .global_sessions$config(
    firebase_config = firebase_config,
    admin_mode = admin_mode,
    is_invite_required = is_invite_required,
    sign_in_providers = sign_in_providers,
    is_email_verification_required = is_email_verification_required,
    is_auth_required = is_auth_required
  )

}
