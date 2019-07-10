#' dashboard_module_ui
#' 
#' @param id the module id
#' 
#' @import shiny shinydashboard highcharter xts dplyr DT
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
        title = "Table",
        DT::DTOutput(ns("active_users_table"))
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
      .global_users$users
    },
    valueFunc = function() {
      .global_users$users
    }
  )
  
  
  active_users_number_prep <- reactive({
    users_list <- global_users_prep()
    users <- unique(lapply(users_list, function(user) user$get_email()))
    
    length(users)
  })
  
  output$active_users_number <- shinydashboard::renderValueBox({
    out <- active_users_number_prep()
    
    shinydashboard::valueBox(
      value = out,
      subtitle = "Active Users",
      icon = icon("users"),
      color = "light-blue",
      width = NULL
    )
  })
  
  
  
  dau_chart_prep <- reactive({
    date_strings <- c("2019-07-01", "2019-07-02", "2019-07-03", "2019-07-04", "2019-07-05",
                      "2019-07-06", "2019-07-07", "2019-07-08", "2019-07-09", "2019-07-10",
                      "2019-07-11", "2019-07-12", "2019-07-13", "2019-07-14")
    
    dates <- do.call("c", lapply(date_strings, as.Date)) #unlist kills dates
    
    df <- dplyr::tibble(
      input = c(3,2,2,3,1,4,2,5,7,6,9,15,16,16),
      date = dates
    )
    
    xts::xts(df$input, order.by = df$date)
  })
  
  output$dau_chart <- highcharter::renderHighchart({
    dat <- dau_chart_prep()
    
    highcharter::highchart(type = "stock") %>% 
      highcharter::hc_title(text = "Daily Active Users") %>% 
      highcharter::hc_xAxis(type = "datetime") %>% 
      highcharter::hc_add_series(data = dat, name = "DAU")
  })
  
  active_users_prep <- reactive({
    users_list <- global_users_prep()
    
    user_emails <- unlist(lapply(users_list, function(user) user$get_email()))
    
    dplyr::tibble(
      email = unique(user_emails),
      time = "13:09:00",
      location = "Atlanta"
    )
  })
  
  output$active_users_table <- DT::renderDataTable({
    out <- active_users_prep()
    
    DT::datatable(
      out,
      rownames = FALSE,
      colnames = c("Email", "Time Signed In", "Location"),
      options = list(
        dom = "t"
      )
    )
  })
}

