#' Automatically set the config environment
#'
#' Determines if the app is deployed to a server or running locally, and adjusts
#' the config environment to "production" or "default" respectively.  This function
#' is almost always called in the "global.R" file of a shiny app immediately before
#' the configuration in the "config.yml" is read in.
#'
#' @param override Set the environment to "default" or "production" manually. \strong{CAUTION:}
#' Be sure you know the difference between "default" & "production" configuration environments.
#' Using the "production" environment will affect the database of the deployed application.
#'
#' @export
#'
#'
set_config_env <- function(override = NULL) {

  if (!(is.null(override) || override %in% c("default", "production"))) {
    stop("invalid `override` argument passed to `set_config_env`", call. = FALSE)
  }

  if (is.null(override)) {
    if (isTRUE(Sys.getenv('SHINY_PORT') == "")) {
      environment <- "default"
    } else {
      environment <- "production"
    }
  } else {
    environment <- override
  }

  Sys.setenv(R_CONFIG_ACTIVE = environment)
}
