#' set_config_env
#'
#' Determines if the app is deployed or running locally and adjusts the
#' config environment accordingly
#'
#' @param override Set the environment to "default" or "production" instead of
#' the value found through session$clientData$url_hostname
#'
#' @export
#'
set_config_env <- function(session, override = NULL) {
  stopifnot(is.null(override) || override %in% c("default", "production"))

  if (is.null(override)) {
    if (isTRUE(session$clientData$url_hostname == "127.0.0.1")) {
      environment <- "default"
    } else {
      environment <- "production"
    }
  } else {
    environment <- override
  }

  Sys.setenv(R_CONFIG_ACTIVE = environment)
}
