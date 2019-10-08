#' configuration for global sessions
#'
#'
#' @param app_name
#' @param firebase_functions_url
#'
#' @export
#'
global_sessions_config <- function(app_name, firebase_functions_url) {

  .global_sessions$config(
    app_name = app_name,
    firebase_functions_url = firebase_functions_url
  )

}