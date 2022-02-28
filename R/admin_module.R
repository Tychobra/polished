#' The UI for the "Admin Panel" dashboard
#'
#' The `shiny` module UI for the `polished` Admin Panel, accessible to Admin users.
#'
#' @param id the Shiny module id.
#' @param options list of HTML elements to customize branding of "Admin Panel".  Valid
#' list element names are `title`, `sidebar_branding`, and `browser_tab_icon`.  See
#' \code{\link{default_admin_ui_options}} for an example.
#' @param include_go_to_shiny_app_button whether or not to include the button to go to
#' the Shiny app.  This argument is set to \code{FALSE} when `polished` is in "admin_mode".
#'
#'
#' @importFrom shiny actionButton NS icon
#' @importFrom shinydashboard dashboardHeader dashboardPage dashboardSidebar dashboardBody sidebarMenu menuItem tabItems
#' @importFrom htmltools HTML tags
#' @importFrom shinyjs useShinyjs
#' @importFrom shinyFeedback useShinyFeedback
#'
#' @return the UI for the "Admin Panel"
#'
#' @export
#'
admin_module_ui <- function(id,
  options = default_admin_ui_options(),
  include_go_to_shiny_app_button = TRUE
) {
  ns <- shiny::NS(id)



  # don't show profile dropdown if in Admin mode.  User cannot log out of admin mode.
  if (isTRUE(.polished$admin_mode)) {
    head <- shinydashboard::dashboardHeader(
      title = options$title
    )
  } else {
    head <- shinydashboard::dashboardHeader(
      title = options$title,
      profile_module_ui(ns("polish__profile"))
    )
  }




  sidebar <- shinydashboard::dashboardSidebar(
    shinydashboard::sidebarMenu(
      id = ns("sidebar_menu"),
      shinydashboard::menuItem(
        text = "User Access",
        tabName = "user_access",
        icon = shiny::icon("users")
      ),


      options$sidebar_branding
    )
  )



  tab_items <- shinydashboard::tabItems(
    user_access_module_ui(ns("user_access"))
  )


  if (isTRUE(include_go_to_shiny_app_button)) {
    shiny_app_button <- htmltools::tags$div(
      style = "position: fixed; bottom: 15px; right: 15px; z-index: 1000;",
      shiny::actionButton(
        ns("go_to_shiny_app"),
        "Shiny App",
        icon = shiny::icon("rocket"),
        class = "btn-primary btn-lg",
        style = "color: #FFFFFF;"
      )
    )
  } else {
    shiny_app_button <- htmltools::tags$div()
  }



  body <- shinydashboard::dashboardBody(
    htmltools::tags$head(
      options$browser_tab_icon,
      htmltools::tags$link(rel = "stylesheet", href = "polish/css/styles.css?version=1")
    ),
    shinyjs::useShinyjs(),
    shinyFeedback::useShinyFeedback(),

    shiny_app_button,

    tab_items
  )




  shinydashboard::dashboardPage(
    head,
    sidebar,
    body,
    title = "Polished",
    skin = "black"
  )
}


#' The server logic for the defaul "Admin Panel" dashboard
#'
#' The `shiny` module server logic for the `polished` Admin Panel, accessible to Admin users.
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

    # to to the Shiny app
    remove_query_string(mode = "push")

    session$reload()

  }, ignoreInit = TRUE)

  shiny::callModule(user_access_module, "user_access")
}
