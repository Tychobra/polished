#' An html button to navigate the the "Admin Panel"
#'
#' The UI portion of the 'shiny' module for the button to navigate to the "Admin Panel".
#' This is the button that, when clicked, navigates a 'polished' admin from your 'shiny' app to the 'polished'
#' Admin Panel.  If your app is set up with the default 'polished' configuration, this button appears
#' in the bottom right of your 'shiny' app.
#'
#' @param id the Shiny module id.
#' @param align The horizontal alignment of the button. Valid options are "right" (the default)
#' or "left".
#' @param vertical_align the vertical alignment of the button.  Valid options are "bottom" (the default)
#' or "top"
#'
#' @importFrom shiny actionButton NS icon
#'
#' @return admin button UI
#'
#' @noRd
#'
admin_button_ui <- function(id, align = "right", vertical_align = "bottom") {
  ns <- shiny::NS(id)

  shiny::actionButton(
    ns("go_to_admin_panel"),
    "Admin Panel",
    icon = shiny::icon("cog"),
    class = "btn-primary btn-lg",
    style = paste0("position: fixed; ", vertical_align, ": 15px; ", align, ": 15px; color: #FFFFFF; z-index: 9999;")
  )
}

#' Server logic for button to go to "Admin Panel"
#'
#' The server logic for the button to navigate 'polished' admins from your 'shiny'
#' app to the 'polished' Admin Panel.
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny observeEvent updateQueryString
#'
#' @noRd
#'
admin_button <- function(input, output, session) {

  shiny::observeEvent(input$go_to_admin_panel, {
    hold_user <- session$userData$user()

    # make sure session has loaded before navigating to admin panel.
    # this fixes an error where session$userData is not set until after the
    # the initial data loads on apps that load large amounts of data during
    # the initial app load.
    req(session$userData$user())

    # remove admin_panel=false from query
    shiny::updateQueryString(
      queryString = paste0("?page=admin_panel"),
      session = session,
      mode = "push"
    )

    session$reload()
  }, ignoreInit = TRUE)
}
