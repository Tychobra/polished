#' verify email page ui
#'
#' @param firebase_config Firebase configuration
#' @param token firebase JWT
#'
#' @export
verify_email_ui <- function(id, firebase_config, token) {
  ns <- NS(id)

  fluidPage(
    fluidRow(
      column(
        12,
        class = "text-center",
        style = "margin-top: 150px",
        h1("Verification Email Sent"),
        tags$button(
          class = "btn action-button",
          id = "resend_verification_email",
          "Resend Verification Email"
        ),
        tags$button(
          class = "btn btn-primary action-button",
          id = ns("confirm_email_verification"),
          "Click Here After You have Verified Your Email"
        )
      )
    ),
    firebase_dependencies(),
    tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
    firebase_init(firebase_config),
    tags$script(src = "polish/all.js"),
    tags$script(src = "polish/verify-email.js"),
    tags$script(
      paste0("
        $(document).on('shiny:sessioninitialized', function() {
          $(document).on('click', '#", ns('confirm_email_verification'), "', function() {
            Shiny.setInputValue('polish__token', '", token, "', { priority: 'event' })
          })
        })
      ")
    )
  )
}

#' server function for verify email module
#'
#' @export
verify_email <- function(input, output, session) {

  observeEvent(input$confirm_email_verification, {

    session$reload()

  }, ignoreInit = TRUE)
}
