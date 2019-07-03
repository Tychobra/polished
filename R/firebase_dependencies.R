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
#' @examples
#'
#' firebase_dependencies()
#'
firebase_dependencies <- function(services = c("auth", "firestore")) {

  services <- unique(services)

  stopifnot(all(services %in% c("auth", "firestore", "functions", "messaging", "storage")))


  scripts_to_load <- paste0("https://www.gstatic.com/firebasejs/6.2.4/firebase-", services, ".js")

  shiny::tagList(
    tags$script(src = "https://www.gstatic.com/firebasejs/6.2.4/firebase-app.js"),
    lapply(scripts_to_load, function(script_src) {
      htmltools::tags$script(src = script_src)
    })
  )
}
