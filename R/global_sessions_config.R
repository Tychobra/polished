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
#' @param sign_in_providers the sign in providers to enable.  Valid values are \code{"google"}
#' \code{"email"}, \code{"microsoft"}, and/or \code{"facebook"}. Defaults to \code{"email"}.
#' @param is_email_verification_required \code{TRUE} by default.  Whether or not to require the user to
#' verify their email before accessing your Shiny app.
#' @param is_auth_required \code{TRUE} by default.  Whether or not to require users to be signed
#' in to access the app.  It can be useful to set this argument to \code{FALSE} if you want to
#' allow user to do certain actions (such as viewing charts and tables) without signing in,
#' and only require users to sign in if they want to save data to your database.
#' @param sentry_dsn either \code{NULL}, the default, or your Sentry project DSN.
#' @param cookie_expires the number of days before a user's cookie expires.
#' Set to \code{NULL} to force Sign Out at session end. This argument is passed to
#' the `expires` option in js-cookie: \url{https://github.com/js-cookie/js-cookie#expires}.
#' Default value is `365` (i.e. 1 year)
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
  sign_in_providers = "email",
  is_email_verification_required = TRUE,
  is_auth_required = TRUE,
  sentry_dsn = NULL,
  cookie_expires = 365L
) {

  if (!(length(api_key) == 1 && is.character(api_key))) {
    stop("invalid `api_key` argument passed to `global_sessions_config()`", call. = FALSE)
  }

  if (!((is.numeric(cookie_expires) && cookie_expires > 0) || is.null(cookie_expires))) {
    stop("invalid `cookie_expires` argument passed to `global_sessions_config()`", call. = FALSE)
  }

  current_polished_options <- getOption("polished")
  # get the app uid
  res <- httr::GET(
    url = paste0(current_polished_options$api_url, "/apps"),
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

  app <- tibble::as_tibble(app)

  if (identical(nrow(app), 0L)) {
    stop(paste0("app_name `", app_name, "` does not exist"), call. = FALSE)
  }

  if (!(is.null(sentry_dsn) || (length(sentry_dsn) == 1 && is.character(sentry_dsn)) ) ) {
    stop("invalid `sentry_dsn` argument passed to `global_sessions_config()`", call. = FALSE)
  }

  options_out <- current_polished_options
  options_out$api_key <- api_key
  options_out$app_uid <- app$uid
  options_out$app_name_display <- app_name
  options_out$sentry_dsn <- sentry_dsn
  options_out$cookie_expires <- cookie_expires
  options("polished" = options_out)


  .global_sessions$config(
    firebase_config = firebase_config,
    admin_mode = admin_mode,
    is_invite_required = is_invite_required,
    sign_in_providers = sign_in_providers,
    is_email_verification_required = is_email_verification_required,
    is_auth_required = is_auth_required
  )

}
