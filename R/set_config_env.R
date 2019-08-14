#' set_config_env
#'
#' Determines if the app is deployed on shinyapps.io, where the environment variable USER is 'shiny', 
#' or running locally and adjusts the config environment accordingly
#'
#' @param override Set the environment to "default" or "production" manully. \strong{CAUTION:}
#' Be sure you know the difference between "default" & "production" configuration environments.
#' Using the "production" environment will affect the database of the deployed application.
#'
#' @export
#'
set_config_env <- function(override = NULL) {
  stopifnot(is.null(override) || override %in% c("default", "production"))

  if (is.null(override)) {
    if (isTRUE(Sys.getenv('USER') == "shiny")) {
      environment <- "production"
    } else {
      environment <- "default"
    }
  } else {
    environment <- override
  }

  Sys.setenv(R_CONFIG_ACTIVE = environment)
}
