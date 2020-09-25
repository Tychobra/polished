#' The UI for the "Admin Panel" 'shinydashboard'
#'
#' The 'shiny' module UI for the Admin Panel.
#'
#' @param id the Shiny module id.
#' @param options list of html elements to customize branding of "Admin Panel".  Valid
#' list element names are "title", "sidebar_branding", and "browser_tab_icon".  See
#' \code{\link{default_admin_ui_options}} for an example.
#' @param include_go_to_shiny_app_button whether or not to include the button to go to
#' the Shiny app.  This argument is set to \code{FALSE} when 'polished' is in "admin_mode".
#'
#' @inheritParams secure_ui
#'
#' @importFrom shiny NS icon
#' @importFrom shinydashboard dashboardSidebar dashboardBody sidebarMenu menuItem tabItems
#' @importFrom htmltools HTML tags
#' @importFrom shinyjs useShinyjs
#' @importFrom shinyFeedback useShinyFeedback
#' @importFrom shinydashboardPlus dashboardHeaderPlus dashboardPagePlus
#'
#' @return the UI for the "Admin Panel"
#'
#' @noRd
#'
admin_module_ui <- function(id, custom_admin_ui = NULL,
  options = default_admin_ui_options(),
  include_go_to_shiny_app_button = TRUE
) {
  ns <- shiny::NS(id)

  stopifnot(is.null(custom_admin_ui) || names(custom_admin_ui) == c("menu_items", "tab_items"))


  # don't show profile dropdown if in Admin mode.  User cannot log out of admin mode.
  if (isTRUE(.global_sessions$get_admin_mode())) {
    head <- shinydashboardPlus::dashboardHeaderPlus(
      title = options$title
    )
  } else {
    head <- shinydashboardPlus::dashboardHeaderPlus(
      title = options$title,
      profile_module_ui(ns("polish__profile"))
    )
  }



  if (is.null(custom_admin_ui$menu_items)) {
    sidebar <- shinydashboard::dashboardSidebar(
      shinydashboard::sidebarMenu(
        id = ns("sidebar_menu"),
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
      user_access_module_ui(ns("user_access"))
    )
  } else {
    tab_items <- shinydashboard::tabItems(
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
      tags$link(rel = "stylesheet", href = "polish/css/styles.css")
    ),
    shinyjs::useShinyjs(),
    shinyFeedback::useShinyFeedback(),

    shiny_app_button,

    tab_items
  )




  shinydashboardPlus::dashboardPagePlus(
    head,
    sidebar,
    body,
    title = "Polished",
    skin = "black-light"
  )
}


#' The server logic for the "Admin Panel" 'shinydashboard'
#'
#' The 'shiny' module server logic for the Admin Panel.
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny callModule observeEvent
#'
#' @noRd
#'
admin_module <- function(input, output, session) {
  ns <- session$ns

  shiny::callModule(
    profile_module,
    "polish__profile"
  )

  shiny::observeEvent(input$go_to_shiny_app, {

    # to to the Shiny app
    remove_query_string(mode = "push")

    session$reload()

  }, ignoreInit = TRUE)

  shiny::callModule(user_access_module, "user_access")
}
