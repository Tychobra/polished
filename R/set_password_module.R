



#' Shiny module to set the user's password
#'
#' The user is redirected to this page after they click their email invite.  They
#' set their new password on this page, and sign in to the Shiny app.
#'
#' @param id the shiny module id
#'
#' @importFrom shiny passwordInput
#' @importFrom htmltools tagList
#' @importFrom shinyFeedback loadingButton
#'
set_password_module_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    div(
      style = "width: 350px; margin: 100px auto;",
      class = "text-center",
      shiny::passwordInput(
        inputId = ns("password"),
        label = htmltools::tagList(shiny::icon("unlock-alt"), "set password"),
        width = "100%"
      ),
      div(
        style = "text-align: center;",
        shinyFeedback::loadingButton(
          ns("submit"),
          label = "Set Password",
          class = "btn btn-primary btn-lg",
          style = "width: 100%;",
          loadingLabel = "Registering...",
          loadingClass = "btn btn-primary btn-lg text-center",
          loadingStyle = "width: 100%;"
        )
      )
    ),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    tags$script(src="polish/js/set_password_module.js"),
    tags$script(paste0("set_password_module('", ns(''), "')"))
  )
}

#' Shiny module server logic for verifying the user's email
#'
#' @param input the shiny server input
#' @param output the shiny server output
#' @param session the shiny server session
#'
#' @importFrom shiny observeEvent getQueryString
#' @importFrom shinyFeedback showToast
#' @importFrom httr POST authenticate
#'
#'
set_password_module <- function(input, output, session) {



  shiny::observeEvent(input$submit_from_js, {
    # get the email and passcode from the query string
    query_list <- shiny::getQueryString()
    hold_email <- query_list$email
    verify_code <- query_list$verify_code
    hold_pass <- input$password
    hold_cookie <- input$submit_from_js$cookie

    hashed_cookie <- digest::digest(hold_cookie)

    if (nchar(hold_pass) < 6) {
      shinyFeedback::showToast("error", "Your password must be at least 6 characters")
    } else {
      tryCatch({

        res <- httr::POST(
          url = paste0(.global_sessions$hosted_url, "/set-password-verify"),
          httr::authenticate(
            user = .global_sessions$api_key,
            password = ""
          ),
          query = list(
            email = hold_email,
            verify_code = verify_code,
            password = hold_pass
          )
        )

        httr::stop_for_status(res)

        # verify email reset successful, so sign user in
        res <- .global_sessions$sign_in_email(
          email = hold_email,
          password = hold_pass,
          hashed_cookie = hashed_cookie
        )

        if (!is.null(res$code)) {
          stop(res$message)
        }

        remove_query_string()
        session$reload()

      }, error = function(err) {

        print(err)
        shinyFeedback::showToast("error", err$message)
      })
    }


  })

}
