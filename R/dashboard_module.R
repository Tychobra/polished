#' dashboard_ui
#' 
#' @param id the module id
#' 
#' @import shiny shinydashboard
#' 
#' @export
dashboard_module_ui <- function(id) {
  ns <- NS(id)
  
  tabItem(
    tabName = "dashboard",
    h1("Dashboard")
  )
}

#' dashboard
#' 
#' @import shiny
#' 
#' @export
dashboard_module <- function(input, output, session) {
  ns <- session$ns
}

