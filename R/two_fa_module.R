#' 2 Factor Auth page ui
#'
#' @param id the Shiny module id
#'
#' @importFrom htmltools tags h1
#' @importFrom shiny fluidPage fluidRow column actionButton
#' @importFrom shinyFeedback useShinyFeedback
#'
#' @noRd
#'
two_fa_module_ui <- function(id) {
  ns <- NS(id)

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
          icon("sign-out-alt"),
          class = "pull-right"
        )
      )
    ),
    shiny::fluidRow(
      shiny::column(
        12,
        class = "text-center",
        style = "margin-top: 100px",
        div(
          id = ns("qrcode")
        ),
        h2("Enter your two-factor authentication code"),
        textInput(
          ns("two_fa_code"),
          label = NULL,
          value = ""
        )
      )
    ),
    tags$script(src="https://cdn.rawgit.com/davidshimjs/qrcodejs/gh-pages/qrcode.min.js"),
    tags$script(src = "polish/js/two_fa_module.js?version=4"),
    tags$script(paste0("two_fa_module('", ns(''), "')"))
  )
}


#' Verify email page server logic
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny observeEvent reactivePoll
#' @importFrom shinyFeedback showToast
#' @importFrom httr GET POST content status_code
#' @importFrom stats runif
#'
#' @noRd
#'
two_fa_module <- function(input, output, session) {


  two_fa_code <- reactive({

    out <- NULL
    tryCatch({

      # TODO: add option to get the 2FA code to get_user
      hold <- get_user(
        user_uid = session$userData$user()$user_uid,
        app_uid = .polished$app_uid#,
        #include_two_fa_code = TRUE
      )

      out <- hold$content$two_fa_code

    }, error = function(err) {

      msg <- "unable to get 2FA code"
      print(msg)
      print(err)
      showToast(msg)

      invisible(NULL)
    })

    out
  })

  time_pass <- reactiveVal(NULL)
  observeEvent(two_fa_code(), {

    if (is.na(two_fa_code())) {
      # 2FA code has not been successfully verified and save to database, so create a
      # new secret
      base_32_secret <- sample(c(LETTERS, 2:7), size = 16, replace = TRUE)
    } else {
      base_32_secret <- two_fa_code()
    }

    time_pass(TOTP$new(base_32_secret))

    # send the base 32 secret to the front end to generate the QR code using javascript
    session$sendCustomMessage(
      session$ns("create_qrcode"),
      message = list(
        "base_32_secret" = base_32_secret
      )
    )

  })



  observeEvent(input$two_fa_code, {
    hold_time_pass <- time_pass()

    if (nchar(input$two_fa_code) == 6) {
      browser()
      code <- hold_time_pass$now()

      is_verified <- hold_time_pass$verify(code)

      if (isTRUE(is_verified)) {

        # user entered the time password correctly.

      }

    }

  })

}
