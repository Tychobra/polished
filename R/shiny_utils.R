#' remove_query_string
#'
#' Remove the entire query string
#'
#' @importFrom shiny updateQueryString getDefaultReactiveDomain
#'
remove_query_string <- function(session = shiny::getDefaultReactiveDomain()) {

  shiny::updateQueryString(
    session$clientData$url_pathname,
    mode = "replace",
    session = session
  )
}
