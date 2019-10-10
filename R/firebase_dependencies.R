#' load the Firebase dependencies into the ui
#'
#'
#' @param services character vector of Firebase services to load into the ui.  Valid strings are
#' "auth", "firestore", "functions", "messaging", and "storage"
#'
#' @export
#'
#' @return the html <script> tabs with the firebase dependencies
#'
#' @importFrom htmltools tagList tags
#'
#' @examples
#'
#' firebase_dependencies()
#'
firebase_dependencies <- function(services = c("auth")) {

  services <- unique(services)

  stopifnot(all(services %in% c("auth", "firestore", "functions", "messaging", "storage")))


  scripts_to_load <- paste0("https://www.gstatic.com/firebasejs/7.1.0/firebase-", services, ".js")

  htmltools::tagList(
    tags$script(src = "https://www.gstatic.com/firebasejs/7.1.0/firebase-app.js"),
    lapply(scripts_to_load, function(script_src) {
      htmltools::tags$script(src = script_src)
    })
  )
}
