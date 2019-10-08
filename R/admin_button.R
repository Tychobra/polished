#' admin_button_ui
#'
#' The default UI for the admin button
#'
#' @param id the Shiny module id.
#'
#' @import shiny
#'
#' @return admin button UI
#'
#' @export
#'
admin_button_ui <- function(id) {
  ns <- NS(id)

  shiny::actionButton(
    ns("go_to_admin_panel"),
    "Admin Panel",
    icon = icon("cog"),
    class = "btn-primary btn-lg",
    style = "position: fixed; bottom: 15px; right: 15px; color: #FFFFFF;"
  )
}

#' admin_button
#'
#' the server logic for the admin button
#'
#' @import shiny
#'
#'
admin_button <- function(input, output, session) {

  shiny::observeEvent(input$go_to_admin_panel, {

    #session$sendCustomMessage(
    #  "polish__show_loading",
    #  message = list(
    #    text = "Loading..."
    #  )
    #)

    # if user is an admin and is signed into the Shiny app as another user, then
    # clear clear the signed in as user
    #polished_user <- session$userData$user()
    #global_user <- .global_sessions$find(polished_user$token)

    # TODO: clear signed in as in .global_sessions
    #global_user$clear_signed_in_as()

    # remove admin_panel=false from query
    shiny::updateQueryString(
      queryString = paste0("?admin_panel=true"),
      session = session,
      mode = "replace"
    )

    session$reload()
  }, ignoreInit = TRUE)
}
