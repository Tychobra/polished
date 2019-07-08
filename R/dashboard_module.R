#' dashboard_module_ui
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
    shiny::fluidRow(
      shiny::column(
        3,
        shinydashboard::valueBox(
          value = 6,
          subtitle = "Total Users",
          icon = icon("users"),
          color = "blue",
          width = 12
        )
      ),
      shiny::column(
        3,
        shinydashboard::valueBox(
          value = 1,
          subtitle = "Active Users",
          icon = icon("users"),
          color = "light-blue",
          width = 12
        )
      ),
      shiny::column(
        3,
        shinydashboard::valueBox(
          value = 4,
          subtitle = "DAU",
          icon = icon("users"),
          color = "teal",
          width = 12
        )
      ),
      shiny::column(
        3,
        shinydashboard::valueBox(
          value = 2,
          subtitle = "MAU",
          icon = icon("users"),
          color = "green",
          width = 12
        )
      )
    )
  )
}

#' dashboard_module
#' 
#' @import shiny
#' 
#' @export
dashboard_module <- function(input, output, session) {
  ns <- session$ns
}

