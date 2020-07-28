#' the UI for a Shiny module to reset password
#'
#' @param id the Shiny module id
#'
#' @importFrom shiny actionLink
#' @importFrom shinyFeedback useShinyFeedback
#'
#' @export
reset_password_module_ui <- function(id) {
  ns <- NS(id)

  tagList(
    shinyFeedback::useShinyFeedback(feedback = FALSE),
    shiny::actionLink(
      inputId = ns("reset_password"),
      "Forgot your password?"
    )
  )
}

#' server logic for Shiny module to reset password
#'
#' This function sends s request to the polished.tech API to reset a user's
#' password.
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#' @param email A reactive value returning the email address to send the password
#' reset email to.
#'
#' @importFrom shiny observeEvent
#' @importFrom httr POST authenticate status_code
#' @importFrom jsonlite fromJSON
#' @importFrom shinyFeedback showToast
#'
#' @export
#'
reset_password_module <- function(input, output, session, email) {


  shiny::observeEvent(input$reset_password, {
    hold_email <- email()

    tryCatch({
      res <- httr::POST(
        url = paste0(.global_sessions$hosted_url, "/reset-password"),
        httr::authenticate(
          user = .global_sessions$api_key,
          password = ""
        ),
        body = list(
          email = hold_email,
          app_uid = .global_sessions$app_name,
          is_invite_required = .global_sessions$is_invite_required
        ),
        encode = "json"
      )

      res_content <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )

      if (!identical(httr::status_code(res), 200L)) {
        stop(res_content$message)
      }

      shinyFeedback::showToast("success", paste0("Password reset email sent to ", hold_email))
    }, error = function(err) {

      print(err)
      shinyFeedback::showToast("error", err$message)
    })


  })

}

