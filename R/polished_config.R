

#' global configuration for `polished` authentication
#'
#' @details
#' This is the primary function for configuring \code{polished}.  It configures your app's instance of
#' the \code{Polished} class that manages \code{polished} authentication.  Call this function in
#' your \code{global.R} file.  See \url{https://github.com/Tychobra/polished/blob/master/inst/examples/polished_example_01/global.R}
#' for a complete example.
#'
#' @param app_name the name of the Shiny app.
#' @param api_key the `polished` API key, available at \url{https://dashboard.polished.tech}.
#' @param firebase_config if using Social Sign In (see \url{https://polished.tech/docs/03-social-sign-in}
#' for more documentation), a list containing your Firebase project configuration (Default: \code{NULL}).
#' This list should have the following named elements:
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
#' @param sign_in_providers a character vector of sign in providers to enable. Valid values are \code{"google"}
#' \code{"email"}, \code{"microsoft"}, and/or \code{"facebook"}. Defaults to \code{"email"}.
#' @param is_email_verification_required \code{TRUE} by default.  Whether or not to require the user to
#' verify their email before accessing your Shiny app.
#' @param is_auth_required \code{TRUE} by default.  Whether or not to require users to be signed
#' in to access the app.  It can be useful to set this argument to \code{FALSE} if you want to
#' allow users to do certain actions (such as viewing charts and tables) without signing in,
#' and only require users to sign in if they want to save data to your database.
#' @param sentry_dsn either \code{NULL}, the default, or your Sentry project's DSN.
#' @param cookie_expires the number of days before a user's cookie expires.
#' Set to \code{NULL} to force Sign Out at session end. This argument is passed to
#' the `expires` option in js-cookie: \url{https://github.com/js-cookie/js-cookie#expires}.
#' Default value is \code{365L} (i.e. 1 year)
#' @param is_2fa_required boolean specifying whether or not 2 factor authentication is required.  Defaults
#' to \code{FALSE}.
#'
#' @export
#'
#'
#' @examples
#'
#' \dontrun{
#' # global.R
#'
#' polished_config(
#'   app_name = "<your app name>",
#'   api_key = "<your API key>",
#'   firebase_config = list(
#'     apiKey = "<Firebase apiKey>",
#'     authDomain = "<Firebase authDomain",
#'     projectId = "<Firebase projectId>"
#'   ),
#'   sign_in_providers = c(
#'     "email",
#'     "google",
#'     "microsoft"
#'   )
#' )
#'
#' }
#'
polished_config <- function(
  app_name,
  api_key = get_api_key(),
  firebase_config = NULL,
  admin_mode = FALSE,
  is_invite_required = TRUE,
  sign_in_providers = "email",
  is_email_verification_required = TRUE,
  sentry_dsn = NULL,
  cookie_expires = 365L,
  is_auth_required = TRUE,
  is_2fa_required = FALSE
) {

  if (!(length(api_key) == 1 && is.character(api_key))) {
    stop("invalid `api_key` argument passed to `polished_config()`", call. = FALSE)
  }

  set_api_key(api_key)

  if (!((is.numeric(cookie_expires) && cookie_expires > 0) || is.null(cookie_expires))) {
    stop("invalid `cookie_expires` argument passed to `polished_config()`", call. = FALSE)
  }

  # get the app uid
  app_res <- get_apps(app_name = app_name)
  app <- app_res$content

  if (identical(nrow(app), 0L)) {
    stop(paste0("app_name `", app_name, "` does not exist"), call. = FALSE)
  }

  if (!(is.null(sentry_dsn) || (length(sentry_dsn) == 1 && is.character(sentry_dsn)) ) ) {
    stop("invalid `sentry_dsn` argument passed to `polished_config()`", call. = FALSE)
  }

  # Throw warning for no Firebase config w/ Social Sign in Providers
  if (is.null(firebase_config) && any(sign_in_providers != "email")) {
    warning(
      "
#########################################################################
Sign In providers (`sign_in_providers`) will not work correctly without a
Firebase configuration (`firebase_config`) provided!
#########################################################################",
call. = FALSE
    )
  }

  if (!is.logical(is_auth_required)) {
    stop("`is_auth_required` must be `TRUE` or `FALSE`", call. = FALSE)
  }

  if (!(length(sign_in_providers) >= 1 && is.character(sign_in_providers))) {
    stop("invalid `sign_in_providers` argument passed to `polished_config()`", call. = FALSE)
  }

  if (!(length(admin_mode) == 1 && is.logical(admin_mode))) {
    stop("invalid `admin_mode` argument passed to `polished_config()`", call. = FALSE)
  }
  if (!(length(is_invite_required) == 1 && is.logical(is_invite_required))) {
    stop("invalid `is_invite_required` argument passed to `polished_config()`", call. = FALSE)
  }
  if (!(length(is_email_verification_required) == 1 && is.logical(is_email_verification_required))) {
    stop("invalid `is_email_verification_required` argument passed to `polished_config()`", call. = FALSE)
  }
  if (!(length(is_2fa_required) == 1 && is.logical(is_2fa_required))) {
    stop("invalid `is_2fa_required` argument passed to `polished_config()`", call. = FALSE)
  }



  assign("app_name", app_name, envir = .polished)
  assign("app_uid", app$uid, envir = .polished)
  assign("api_key", api_key, envir = .polished)
  assign("firebase_config", firebase_config, envir = .polished)
  assign("admin_mode", admin_mode, envir = .polished)
  assign("is_invite_required", is_invite_required, envir = .polished)
  assign("sign_in_providers", sign_in_providers, envir = .polished)
  assign("is_email_verification_required", is_email_verification_required, envir = .polished)
  assign("sentry_dsn", sentry_dsn, envir = .polished)
  assign("cookie_expires", cookie_expires, envir = .polished)
  assign("is_auth_required", is_auth_required, envir = .polished)
  assign("is_2fa_required", is_2fa_required, envir = .polished)


  if (!is.null(firebase_config)) {
    if (length(firebase_config) != 3 ||
        !all(names(firebase_config) %in% c("apiKey", "authDomain", "projectId"))) {
      stop("invalid `firebase_config` argument passed to `polished_config()`", call. = FALSE)
    }
    # if firebase is being used, then we need to get the jwt from Google.  Creating these
    # two values to manage the JWT.
    refresh_jwt_pub_key()
  }

  invisible(NULL)
}

#' @rdname polished_config
#'
#' @param ... arguments to pass to \code{\link{polished_config}}
#'
#' @export
#'
global_sessions_config <- function(
  ...
) {

  .Deprecated("polished_config")


  polished_config(...)
}


#' @export
.polished <- new.env()

