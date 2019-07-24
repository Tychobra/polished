#' verify email page ui
#'
#' @param firebase_config Firebase configuration
#'
#' @importFrom htmltools tags
#' @importFrom shiny textOutput actionLink
#'
#' @export
profile_module_ui <- function(id, firebase_config) {
  ns <- NS(id)

  htmltools::tags$li(
    class = "dropdown",
    htmltools::tags$a(
      href="#",
      class = "dropdown-toggle",
      `data-toggle` = "dropdown",
      htmltools::tags$i(
        class = "fa fa-user"
      )
    ),
    htmltools::tags$ul(
      class = "dropdown-menu",
      htmltools::tags$li(
        shiny::textOutput(ns("auth_user")),
        style='padding: 3px 20px;'
      ),
      htmltools::tags$li(
        shiny::actionLink(
          "polish__sign_out",
          label = "Sign Out",
          icon = icon("sign-out")
        )
      )
    )
  )
}

#' profile module server
#'
#' @export
#'
#' @importFrom shiny renderText observeEvent
#'
#'
profile_module <- function(input, output, session) {

  output$auth_user <- shiny::renderText({
    req(session$userData$current_user())

    session$userData$current_user()$email
  })

  shiny::observeEvent(input$polish__sign_out, {
    req(session$userData$current_user()$email)

    sign_out_from_shiny(session)
  })

}


