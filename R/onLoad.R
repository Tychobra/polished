#' Adds the content of inst/srcjs/ to polish/
#'
#' @importFrom shiny addResourcePath registerInputHandler
#'
#' @noRd
#'
.onLoad <- function(...) {
  shiny::addResourcePath("polish", system.file("assets", package = "polished"))
}
