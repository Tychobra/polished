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
      shinydashboard::valueBox(
        value = 6,
        subtitle = "Total Users",
        icon = icon("users"),
        color = "blue",
        width = 3
      ),
      shinydashboard::valueBoxOutput(
        ns("active_users_number"),
        width = 3
      ),
      shinydashboard::valueBox(
        value = 2,
        subtitle = "DAU",
        icon = icon("users"),
        color = "teal",
        width = 3
      ),
      shinydashboard::valueBox(
        value = 4,
        subtitle = "MAU",
        icon = icon("users"),
        color = "green",
        width = 3
      )
    ),
    shiny::fluidRow(
      shinydashboard::box(
        width = 9,
        title = "Chart",
        highcharter::highchartOutput(ns("dau_chart"))
      ),
      shinydashboard::box(
        width = 3,
        title = "Table"
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
  
  global_users_prep <- shiny::reactivePoll(
    intervalMillis = 1000 * 10, # check every 10 seconds,
    session = session,
    checkFunc = function() {
      length(.global_users$users)
    },
    valueFunc = function() {
      .global_users$users
    }
  )
  
  output$active_users_number <- shinydashboard::renderValueBox({
    shinydashboard::valueBox(
      value = length(global_users_prep()),
      subtitle = "Active Users",
      icon = icon("users"),
      color = "light-blue",
      width = NULL
    )
  })
  
  dau_chart_prep <- reactive({
    c(3,2,2,3,1,4,2,5,7,6,9,15,16,16)
  })
  
  output$dau_chart <- highcharter::renderHighchart({
    dat <- dau_chart_prep()
    
    highcharter::highchart(type = "stock") %>% 
      highcharter::hc_add_series(dat)
  })
}

