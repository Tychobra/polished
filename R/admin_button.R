#' admin_button_ui
#'
#' The default UI for the admin button
#'
#' @param id the Shiny module id.
#'
#' @importFrom shiny actionButton NS icon
#'
#' @return admin button UI
#'
#' @export
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
#' the server logic for the admin button
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
      session$userData$user()$session_uid,
      NA
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
