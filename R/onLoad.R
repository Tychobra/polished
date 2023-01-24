#' Adds the contents of `inst/srcjs/` to `polish/`
#'
#' @importFrom shiny addResourcePath
#' @importFrom httr set_config config
#'
#' @return \code{invisible(NULL)}
#'
#' @noRd
#'
.onLoad <- function(...) {
  shiny::addResourcePath("polish", system.file("assets", package = "polished"))
  httr::set_config(httr::config(http_version = 0))
  set_api_url()

  invisible(NULL)
}
