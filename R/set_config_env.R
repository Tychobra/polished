#' Automatically set the config environment
#'
#' Determines if the app is deployed to a server or running locally, and adjusts
#' the config environment to \code{"production"} or \code{"default"}, respectively.  This function
#' is almost always called in the \code{global.R} file of a Shiny app immediately before
#' the configuration in the \code{config.yml} is read in.
#'
#' @param override Set the environment to \code{"default"} or \code{"production"} manually. \strong{CAUTION:}
#' Be sure you know the difference between \code{"default"} & \code{"production"} configuration environments.
#' Using the \code{"production"} environment will affect the database of the deployed application.
#'
#' @export
#'
#'
set_config_env <- function(override = NULL) {

  if (!(is.null(override) || override %in% c("default", "development", "production"))) {
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
