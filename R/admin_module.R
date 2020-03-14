#' admin_ui
#'
#' @param id the Shiny module id
#' @param firebase_config list of Firebase config
#' @param custom_admin_ui Either `NULL`, the default, or a list of 2 elements containing custom
#' ui to add addtional `shinydashboard` tabs to the Polished admin panel.
#' @param options list of html elements to customize branding of Admin Panel.
#'
#' @importFrom shiny NS icon
#' @importFrom shinydashboard dashboardHeader dashboardSidebar dashboardBody dashboardPage sidebarMenu menuItem tabItems
#' @importFrom htmltools HTML tags
#'
#' @export
#'
admin_module_ui <- function(id, firebase_config, custom_admin_ui = NULL,
  options = default_admin_ui_options(),
  include_go_to_shiny_app_button = TRUE
) {
  ns <- shiny::NS(id)

  stopifnot(is.null(custom_admin_ui) || names(custom_admin_ui) == c("menu_items", "tab_items"))

  head <- shinydashboard::dashboardHeader(
    title = options$title,
    profile_module_ui(ns("polish__profile"))
  )

  if (is.null(custom_admin_ui$menu_items)) {
    sidebar <- shinydashboard::dashboardSidebar(
      shinydashboard::sidebarMenu(
        id = ns("sidebar_menu"),
        menuItem(
          text = "Dashboard",
          tabName = "dashboard",
          icon = shiny::icon("dashboard")
        ),
        menuItem(
          text = "User Access",
          tabName = "user_access",
          icon = shiny::icon("users")
        ),


        options$sidebar_branding
      )
    )
  } else {
    sidebar <- shinydashboard::dashboardSidebar(
      sidebarMenu(
        id = ns("sidebar_menu"),
        shinydashboard::menuItem(
          text = "Dashboard",
          tabName = "dashboard",
          icon = shiny::icon("dashboard")
        ),
        shinydashboard::menuItem(
          text = "User Access",
          tabName = "user_access",
          icon = shiny::icon("users")
        ),

        custom_admin_ui$menu_items,

        options$sidebar_branding
      )
    )
  }


  if (is.null(custom_admin_ui$tab_items)) {
    tab_items <- shinydashboard::tabItems(
      dashboard_module_ui(ns("dashboard")),
      user_access_module_ui(ns("user_access"))
    )
  } else {
    tab_items <- shinydashboard::tabItems(
      dashboard_module_ui(ns("dashboard")),
      user_access_module_ui(ns("user_access")),
      custom_admin_ui$tab_items
    )
  }

  if (isTRUE(include_go_to_shiny_app_button)) {
    shiny_app_button <- div(
      style = "position: fixed; bottom: 15px; right: 15px; z-index: 1000;",
      actionButton(
        ns("go_to_shiny_app"),
        "Shiny App",
        icon = shiny::icon("rocket"),
        class = "btn-primary btn-lg",
        style = "color: #FFFFFF;"
      )
    )
  } else {
    shiny_app_button <- div()
  }



  body <- shinydashboard::dashboardBody(
    htmltools::tags$head(
      options$browser_tab_icon,
      firebase_dependencies(),
      firebase_init(firebase_config)
    ),
    shinyjs::useShinyjs(),
    shinytoastr::useToastr(),

    shiny_app_button,

    tab_items,


    tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js")
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
#' @importFrom shiny callModule observeEvent
#'
#' @export
#'
admin_module <- function(input, output, session) {
  ns <- session$ns

  shiny::callModule(
    profile_module,
    "polish__profile"
  )

  shiny::observeEvent(input$go_to_shiny_app, {

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


  shiny::callModule(dashboard_module, "dashboard")
  shiny::callModule(user_access_module, "user_access")
}
