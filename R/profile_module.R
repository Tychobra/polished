#' verify email page ui
#'
#' @param id the Shiny module id
#'
#' @importFrom htmltools tags
#' @importFrom shiny textOutput actionLink
#'
#' @export
profile_module_ui <- function(id) {
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
          ns("polish__sign_out"),
          label = "Sign Out",
          icon = icon("sign-out")
        )
      )
    )
  )
}

#' profile module server
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @export
#'
#' @importFrom shiny renderText observeEvent req
#'
#'
profile_module <- function(input, output, session) {

  output$auth_user <- shiny::renderText({
    shiny::req(session$userData$user())

    session$userData$user()$email
  })


  shiny::observeEvent(input$polish__sign_out, {
    shiny::req(session$userData$user()$email)

    sign_out_from_shiny(session)

    session$reload()
  })
}


