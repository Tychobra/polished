#' Profile Module UI
#'
#' Generates the UI for a user profile dropdown button to be used with the
#' \code{shinydashboard} package.
#'
#' @param id the Shiny module id.
#' @param other_lis additional \code{<li>} HTML tags to place between the email address
#' and the Sign out button in the user profile dropdown.  This is often used to
#' add a user "My Account" page/app where the user can set their account settings.
#'
#' @return the UI to create the profile dropdown.
#'
#' @importFrom htmltools tags
#' @importFrom shiny textOutput actionLink NS icon
#'
#' @export
profile_module_ui <- function(id, other_lis = NULL) {
  ns <- shiny::NS(id)

  htmltools::tags$li(
    class = "dropdown",
    htmltools::tags$a(
      href = "#",
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
        style = 'padding: 3px 20px;'
      ),
      # Other links that can be used to link anything.  Often used to take the
      # user to their "Account" app/page.
      other_lis,

      htmltools::tags$li(
        shiny::actionLink(
          ns("polish__sign_out"),
          label = "Sign Out",
          icon = shiny::icon("sign-out-alt")
        )
      )
    )
  )
}

#' Profile Module Server
#'
#' The server logic to accompany the  \code{\link{profile_module_ui}}.
#'
#' @param input the Shiny server \code{input}
#' @param output the Shiny server \code{output}
#' @param session the Shiny server \code{session}
#'
#' @return \code{invisible(NULL)}
#'
#' @export
#'
#' @importFrom shiny renderText observeEvent req
#' @importFrom shinyFeedback showToast
#'
#'
profile_module <- function(input, output, session) {

  output$auth_user <- shiny::renderText({
    shiny::req(session$userData$user())

    session$userData$user()$email
  })


  shiny::observeEvent(input$polish__sign_out, {
    shiny::req(session$userData$user()$email)

    tryCatch({

      sign_out_from_shiny(session)
      session$reload()

    }, error = function(err) {

      msg <- "Sign Out Error"
      warning(msg)
      warning(conditionMessage(err))
      shinyFeedback::showToast(
        "error",
        msg,
        .options = polished_toast_options
      )

      invisible(NULL)
    })

  })

  invisible(NULL)
}


