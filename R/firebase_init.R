#' firebase_init
#'
#' @param firebase_config list of firebase configuration
#'
#' @export
#'
#' @return a character string of JavaScript code defining firebaseConfig
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
#'   databaseURL = "your Firebase database URL",
#'   projectId = "your Firebase Project ID"
#' )
#'
#' firebase_init(my_config)
#' }
firebase_init <- function(firebase_config) {

  htmltools::tagList(
    tags$script(
      paste0("
        var firebaseConfig = {
          apiKey: '", firebase_config$apiKey, "',
          authDomain: '", firebase_config$authDomain, "',
          databaseURL: '", firebase_config$databaseURL, "',
          projectId: '", firebase_config$projectId, "'
        }

        firebase.initializeApp(firebaseConfig)
      ")
    )
  )
}
