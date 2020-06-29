#' admin_button_ui
#'
#' The default UI for the admin button 'shiny' module.  This is the button that,
#' when clicked, navigates a 'polished' admin from your 'shiny' app to the 'polished'
#' Admin Panel.
#'
#' @param id the Shiny module id.
#'
#' @importFrom shiny actionButton NS icon
#'
#' @return admin button UI
#'
#'
admin_button_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::actionButton(
    ns("go_to_admin_panel"),
    "Admin Panel",
    icon = shiny::icon("cog"),
    class = "btn-primary btn-lg",
    style = "position: fixed; bottom: 15px; right: 15px; color: #FFFFFF; z-index: 9999;"
  )
}

#' admin_button
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
#'
admin_button <- function(input, output, session) {

  shiny::observeEvent(input$go_to_admin_panel, {
    hold_user <- session$userData$user()

    # make sure session has loaded before navigating to admin panel.
    # this fixes an error where session$userData is not set until after the
    # the initial data loads on apps that load large amounts of data during
    # the initial app load.
    req(session$userData$user())

    session$sendCustomMessage(
      "polish__show_loading",
      message = list(
        text = "Loading..."
      )
    )


    # clear signed in as in .global_sessions
    .global_sessions$set_signed_in_as(
      hold_user$session_uid,
      NA,
      user_uid = hold_user$user_uid
    )

    # remove admin_panel=false from query
    shiny::updateQueryString(
      queryString = paste0("?page=admin_panel"),
      session = session,
      mode = "replace"
    )

    session$reload()
  }, ignoreInit = TRUE)
}
