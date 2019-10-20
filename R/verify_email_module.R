#' verify email page ui
#'
#' @param id the Shiny module id
#' @param firebase_config Firebase configuration
#'
#' @importFrom htmltools tags h1
#' @importFrom shiny fluidPage fluidRow column
#' @importFrom shinytoastr useToastr
#'
#' @export
verify_email_ui <- function(id, firebase_config) {
  ns <- NS(id)

  fluidPage(
    tags$head(
      tags$link(rel = "stylesheet", href = "polish/css/all.css"),
      tags$link(rel = "shortcut icon", href = "polish/images/tychobra-icon-blue.png")
    ),
    shinytoastr::useToastr(),
    fluidRow(
      column(
        12,
        class = "text-center",
        style = "margin-top: 150px",
        h1("Verification Email Sent"),
        tags$button(
          class = "btn btn-default action-button",
          id = "resend_verification_email",
          "Resend Verification Email"
        )
      )
    ),
    firebase_dependencies(),
    firebase_init(firebase_config),
    tags$script(src = "polish/js/toast_options.js"),
    tags$script(src = "polish/js/verify_email.js")
  )
}


