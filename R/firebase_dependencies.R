#' load the Firebase JavaScript dependencies into the ui
#'
#' @param services character vector of Firebase services to load into the ui.  Valid strings are
#' "auth", "firestore", "functions", "messaging", and "storage"
#' @param firebase_version character string of the Firebase version.  Defaults to 7.15.5.
#'
#' @export
#'
#' @return the html <script> tags for the Firebase JavaScript dependencies
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
