#' Adds the content of inst/srcjs/ to polish/
#'
#' @importFrom shiny addResourcePath registerInputHandler
#' @importFrom httr set_config config
#'
#' @noRd
#'
.onLoad <- function(...) {
  shiny::addResourcePath("polish", system.file("assets", package = "polished"))
  httr::set_config(httr::config(http_version = 0))

  invisible()
}
