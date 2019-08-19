#' firebase_init
#'
#' @param firebase_config list of firebase configuration
#'
#' @export
#'
#' @return a character string of JavaScript code defining firebaseConfig
#'
#' @examples
#'
#' my_config <- list(
#'   apiKey = "your Firebase API key",
#'   authDomain = "your Firebase auth domain",
#'   databaseURL = "your Firebase database URL",
#'   projectId = "your Firebase Project ID"
#' )
#'
#' firebase_config(my_config)
#'
firebase_init <- function(firebase_config) {

  tagList(
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
