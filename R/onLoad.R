#' Adds the content of inst/srcjs/ to polish/
#'
#' @importFrom shiny addResourcePath registerInputHandler
#' @importFrom tibble tibble
#' @importFrom tidyr spread
#'
#' @noRd
#'
.onLoad <- function(...) {
  shiny::addResourcePath("polish", system.file("assets", package = "polished"))
}
