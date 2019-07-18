library(shiny)
library(DT)
library(shinyjs)
library(shinycssloaders)

#' admin_ui
#'
#' @param firebase_config list of Firebase config
#'
#' @import shiny
#' @import DT
#' @import shinyjs
#' @import shinydashboard
#'
#' @export
#'
admin_module_ui <- function(id, firebase_config) {
  ns <- NS(id)


  head <- shinydashboard::dashboardHeader(
    title = "Polished Admin",
    profile_module_ui(ns("polish__profile"))
  )

  sidebar <- shinydashboard::dashboardSidebar(
    sidebarMenu(
      id = ns("sidebar_menu"),
      menuItem(
        text = "Dashboard",
        tabName = "dashboard",
        icon = icon("dashboard")
      ),
      menuItem(
        text = "User Access",
        tabName = "user_access",
        icon = icon("users")
      ),
      img(
        style = "position: fixed; bottom: 0; left: 0; width: 55px;",
        src = "polish/images/tychobra_logo_white.svg"
      )
    )
  )

  body <- shinydashboard::dashboardBody(
    shiny::tags$head(
      tags$link(rel = "shortcut icon", href = "polish/images/tychobra-icon-blue.png"),
      #tags$link(rel = "stylesheet", href = "styles.css"),
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.css"),
      firebase_dependencies(),
      firebase_init(firebase_config)
    ),
    shinyjs::useShinyjs(),

    div(
      style = "position: fixed; bottom: 15px; right: 15px; z-index: 1000;",
      actionButton(
        ns("go_to_shiny_app"),
        "Shiny App",
        icon = icon("rocket"),
        class = "btn-primary btn-lg",
        style = "color: #FFFFFF;"
      )
    ),

    tabItems(
      # shinydashboard::tabItem(
      #   tabName = "dashboard",
      #   h1("Dashboard"),
      #   verbatimTextOutput(ns("global_users_out"))
      # ),
      dashboard_module_ui(ns("dashboard")),
      user_access_module_ui(ns("user_access"))
    ),

    tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.js"),
    tags$script(src = "polish/js/all.js"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    tags$script(src = "polish/js/auth-state.js"),
    tags$script(src = "polish/js/admin.js")
  )




  shinydashboard::dashboardPage(
    head,
    sidebar,
    body,
    skin = "black"
  )
}


#' admin_module
#'
#' @export
#'
admin_module <- function(input, output, session) {
  ns <- session$ns

  callModule(
    profile_module,
    "polish__profile"
  )

  observeEvent(input$go_to_shiny_app, {

    session$sendCustomMessage(
      "polish__show_loading",
      message = list(
        text = "Loading..."
      )
    )

    # to to the Shiny app
    remove_query_string(session)

    session$reload()

  }, ignoreInit = TRUE)

  observeEvent(input$polish__sign_out, {
    sign_out_from_shiny(session)
  })

  callModule(dashboard_module, "dashboard")
  callModule(user_access_module, "user_access")
}
