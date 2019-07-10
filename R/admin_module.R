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
    tags$li(
      class = "dropdown",
      tags$a(
        href="#",
        class = "dropdown-toggle",
        `data-toggle` = "dropdown",
        tags$i(
          class = "fa fa-user"
        )
      ),
      tags$ul(
        class = "dropdown-menu",
        tags$li(
          textOutput(ns("polish__user")),
          style='padding: 3px 20px;'
        ),
        tags$li(
          actionLink(
            "polish__sign_out",
            "Sign Out",
            icon("sign-out")
          )
        )
      )
    )
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
        style = "position: fixed; bottom: 0; left: 0; width: 230px;",
        src = "https://res.cloudinary.com/dxqnb8xjb/image/upload/v1533565833/tychobra_logo_blue_co_name_jekv4a.png"
      )
    )
  )

  body <- shinydashboard::dashboardBody(
    shiny::tags$head(
      tags$link(rel = "shortcut icon", href = "https://res.cloudinary.com/dxqnb8xjb/image/upload/v1510505618/tychobra-logo-blue_d2k9vt.png"),
      #tags$link(rel = "stylesheet", href = "styles.css"),
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.css")
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
    firebase_dependencies(),
    tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.js"),
    tags$script(
      src = "https://code.jquery.com/ui/1.12.1/jquery-ui.min.js",
      integrity = "sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU=",
      crossorigin = "anonymous"
    ),
    firebase_init(firebase_config),
    tags$script(src = "polish/all.js"),
    tags$script(src = "polish/auth-state.js"),
    tags$script(src = "polish/admin.js")
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

  output$polish__user <- renderText({
    session$userData$current_user()$email
  })

  observeEvent(input$go_to_shiny_app, {

    # to to the Shiny app
    query_token <- parseQueryString(session$clientData$url_search)$token

    updateQueryString(
      queryString = paste0("?token=", query_token, "&admin_panel=false"),
      session = session,
      mode = "replace"
    )

    session$reload()

  }, ignoreInit = TRUE)

  observeEvent(input$polish__sign_out, {
    sign_out_from_shiny(session)
  })

  callModule(dashboard_module, "dashboard")
  callModule(user_access_module, "user_access")
}
