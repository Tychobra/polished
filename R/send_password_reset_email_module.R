#' the UI for a Shiny module to send a password reset email
#'
#' @param id the Shiny module \code{id}
#' @param link_text text to use for the password reset link.
#'
#' @importFrom htmltools tagList
#' @importFrom shiny actionLink NS
#' @importFrom shinyFeedback useShinyFeedback
#'
#' @export
send_password_reset_email_module_ui <- function(id, link_text = "Forgot your password?") {
  ns <- shiny::NS(id)

  tagList(
    shinyFeedback::useShinyFeedback(feedback = FALSE),
    shiny::actionLink(
      inputId = ns("reset_password"),
      link_text
    )
  )
}

#' the server logic for a Shiny module to send a password reset email
#'
#' This function sends a request to the \url{https://polished.tech} API to reset a user's
#' password.
#'
#' @param input the Shiny server \code{input}
#' @param output the Shiny server \code{output}
#' @param session the Shiny server \code{session}
#' @param email A reactive value returning the email address to send the password
#' reset email to.
#'
#' @importFrom shiny observeEvent
#' @importFrom httr POST authenticate content status_code
#' @importFrom jsonlite fromJSON
#' @importFrom shinyFeedback showToast
#'
#' @export
#'
send_password_reset_email_module <- function(input, output, session, email) {


  shiny::observeEvent(input$reset_password, {
    hold_email <- email()

    tryCatch({
      # Stop if email is empty
      if (identical(nchar(trimws(hold_email, which = "both")), 0L)) {
        stop("Enter a valid email before clicking the Password Reset link.", call. = FALSE)
      }


      res <- httr::POST(
        url = paste0(.polished$api_url, "/send-password-reset-email"),
        httr::authenticate(
          user = get_api_key(),
          password = ""
        ),
        body = list(
          email = hold_email,
          app_uid = .polished$app_uid,
          is_invite_required = .polished$is_invite_required
        ),
        encode = "json"
      )

      res_content <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )

      if (!identical(httr::status_code(res), 200L)) {
        stop(res_content$error, call. = FALSE)
      }

      shinyFeedback::showToast(
        "success",
        paste0("Password reset email sent to ", hold_email),
        .options = polished_toast_options
      )
    }, error = function(err) {
      print(err)
      shinyFeedback::showToast(
        "error",
        err$message,
        .options = polished_toast_options
      )
    })

  })

}

