#' admin_ui
#'
#' @param id the Shiny module id
#' @param firebase_config list of Firebase config
#' @param custom_admin_ui Either `NULL`, the default, or a list of 2 elements containing custom
#' ui to add addtional `shinydashboard` tabs to the Polished admin panel.
#'
#' @import shiny
#' @import DT
#' @import shinyjs
#' @import shinydashboard
#' @import htmltools
#'
#' @export
#'
admin_module_ui <- function(id, firebase_config, custom_admin_ui = NULL) {
  ns <- NS(id)

  stopifnot(is.null(custom_admin_ui) || names(custom_admin_ui) == c("menu_items", "tab_items"))

  head <- shinydashboard::dashboardHeader(
    title = shiny::titlePanel(
      htmltools::HTML(
        paste0(
          htmltools::tags$a(
            href = "https://polished.tychobra.com",
            htmltools::tags$img(
              src="polish/images/polished_hex.png",
              height = "50px",
              alt = "Polished Logo",
              style = "margin-top: -20px; float: left;"
            )
          ),
          htmltools::tags$span("Polished", style='float: left; font-size: 37px !important; margin-top: -14px !important; margin-left: 10px; padding-top: 0 !important;')
        )
      ),
      windowTitle = "Polished"
    ),
    profile_module_ui(ns("polish__profile"))
  )

  if (is.null(custom_admin_ui$menu_items)) {
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


        tags$a(
          href = "https://www.tychobra.com/",
          img(
            style = "position: fixed; bottom: 0; left: 0; width: 230px;",
            src = "polish/images/tychobra_logo_blue_co_name.png"
          )
        )
      )
    )
  } else {
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

        custom_admin_ui$menu_items,

        tags$a(
          href = "https://www.tychobra.com/",
          img(
            style = "position: fixed; bottom: 0; left: 0; width: 230px;",
            src = "polish/images/tychobra_logo_blue_co_name.png"
          )
        )
      )
    )
  }


  if (is.null(custom_admin_ui$tab_items)) {
    tab_items <- tabItems(
      dashboard_module_ui(ns("dashboard")),
      user_access_module_ui(ns("user_access"))
    )
  } else {
    tab_items <- tabItems(
      dashboard_module_ui(ns("dashboard")),
      user_access_module_ui(ns("user_access")),
      custom_admin_ui$tab_items
    )
  }


  body <- shinydashboard::dashboardBody(
    shiny::tags$head(
      tags$link(rel = "shortcut icon", href = "polish/images/polished_hex.png"),
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

    tab_items,


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
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
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
