#' Load the Firebase JavaScript dependencies into the UI
#'
#' For `Social Sign In`, \code{polished} uses Firebase JavaScript dependencies.
#' This function loads the required Firebase JavaScript dependencies in the the
#' UI of your Shiny app.
#'
#' @param services character vector of Firebase services to load into the UI.  Valid strings are
#' \code{"auth"} (default), \code{"firestore"}, \code{"functions"}, \code{"messaging"}, and \code{"storage"}
#' @param firebase_version character string of the Firebase version.  Defaults to \code{"7.15.5"}.
#'
#' @export
#'
#' @return the HTML \code{<script>} tags for the Firebase JavaScript dependencies
#'
#' @importFrom htmltools tagList tags
#'
#' @examples
#'
#' firebase_dependencies()
#'
firebase_dependencies <- function(services = c("auth"), firebase_version = "7.15.5") {

  services <- unique(services)

  stopifnot(all(services %in% c("auth", "firestore", "functions", "messaging", "storage")))


  scripts_to_load <- paste0("https://www.gstatic.com/firebasejs/", firebase_version, "/firebase-", services, ".js")

  htmltools::tagList(
    tags$script(src = paste0("https://www.gstatic.com/firebasejs/", firebase_version, "/firebase-app.js")),
    lapply(scripts_to_load, function(script_src) {
      htmltools::tags$script(src = script_src)
    })
  )
}
