#' Initialize Firebase
#'
#' Executes a few lines of JavaScript to initialize Firebase. This function should be
#' called in your Shiny UI immediately after \code{\link{firebase_dependencies}}.
#'
#' @param firebase_config named \code{list} of firebase configuration values.
#' Required values are:
#' - `apiKey`
#' - `authDomain`
#' - `projectId`
#'
#' @export
#'
#' @return a character string of JavaScript code to initialize Firebase
#'
#' @importFrom htmltools tagList tags
#'
#' @examples
#'
#'
#' \dontrun{
#' my_config <- list(
#'   apiKey = "your Firebase API key",
#'   authDomain = "your Firebase auth domain",
#'   projectId = "your Firebase Project ID"
#' )
#'
#' firebase_init(my_config)
#' }
firebase_init <- function(firebase_config) {

  htmltools::tagList(
    htmltools::tags$script(
      paste0("
        var firebaseConfig = {
          apiKey: '", firebase_config$apiKey, "',
          authDomain: '", firebase_config$authDomain, "',
          projectId: '", firebase_config$projectId, "'
        }

        firebase.initializeApp(firebaseConfig)
      ")
    )
  )
}
