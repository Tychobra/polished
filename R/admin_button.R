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
    style = "position: fixed; bottom: 15px; right: 15px; color: #FFFFFF;"
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

    session$sendCustomMessage(
      "polish__show_loading",
      message = list(
        text = "Loading..."
      )
    )

    # TODO: clear signed in as in .global_sessions
    .global_sessions$clear_signed_in_as(session$userData$user()$token)

    # remove admin_panel=false from query
    shiny::updateQueryString(
      queryString = paste0("?admin_panel=true"),
      session = session,
      mode = "replace"
    )

    session$reload()
  }, ignoreInit = TRUE)
}
