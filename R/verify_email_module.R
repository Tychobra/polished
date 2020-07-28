#' Verify email page ui
#'
#' @param id the Shiny module id
#'
#' @importFrom htmltools tags h1
#' @importFrom shiny fluidPage fluidRow column actionButton
#' @importFrom shinyFeedback useShinyFeedback
#'
#' @noRd
#'
verify_email_module_ui <- function(id) {
  ns <- NS(id)

  firebase_config <- .global_sessions$firebase_config

  fluidPage(
    tags$head(
      tags$link(rel = "shortcut icon", href = "polish/images/tychobra-icon-blue.png"),
      shinyFeedback::useShinyFeedback(feedback = FALSE, toastr = TRUE)
    ),
    shinyFeedback::useShinyFeedback(),
    shiny::fluidRow(
      shiny::column(
        12,
        br(),
        shiny::actionButton(
          ns("sign_out"),
          label = "Sign Out",
          icon("sign-out"),
          class = "pull-right"
        )
      )
    ),
    shiny::fluidRow(
      shiny::column(
        12,
        class = "text-center",
        style = "margin-top: 100px",
        h1("Verification Email Sent"),
        shiny::actionButton(
          ns("resend_verification_email"),
          label = "Resend Verification Email",
          class = "btn-default"
        )
      )
    )
  )
}


#' Verify email page server logic
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny observeEvent
#' @importFrom shinyFeedback showToast
#'
#' @noRd
#'
verify_email_module <- function(input, output, session) {




  shiny::observeEvent(input$resend_verification_email, {

    tryCatch({
      hold_email <- session$userData$user()$email


      res <- httr::POST(
        url = paste0(.global_sessions$hosted_url, "/resend-verification-email"),
        httr::authenticate(
          user = .global_sessions$api_key,
          password = ""
        ),
        body = list(
          email = hold_email,
          user_uid = session$userData$user()$user_uid,
          app_uid = .global_sessions$app_name
        ),
        encode = "json"
      )

      httr::stop_for_status(res)

      shinyFeedback::showToast("success", paste0("Verification email send to ", hold_email))
    }, error = function(err) {


      print("[polished] error - resending verification email")
      print(err)

      shinyFeedback::showToast("error", "Error resending verification email")
    })

  })

  # sign out triggered from JS
  shiny::observeEvent(input$sign_out, {
    sign_out_from_shiny(session)
    session$reload()
  })

}
