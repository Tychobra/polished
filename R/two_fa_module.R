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
    style = "background-color: #eee; height: 100vh;",
    tags$style("
      input {
        text-align: right;
      }
    "),
    shinyjs::useShinyjs(),
    tags$head(
      tags$link(rel = "shortcut icon", href = "polish/images/tychobra-icon-blue.png"),
      shinyFeedback::useShinyFeedback(feedback = FALSE, toastr = TRUE)
    ),
    shiny::fluidRow(
      shiny::column(
        12,
        div(
          style = "
            max-width: 630px;
            width: 100%;
            margin: 150px auto;
            text-align: center;
            background-color: #FFF;
            border-radius: 8px;
            padding-top: 30px;
            padding-bottom: 35px;
            box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
          ",
          shinyjs::hidden(div(
            id = ns("qrcode_div"),
            style = "text-center",
            h3("Scan QR in authenticator app"),
            br(),
            br(),
            div(
              style = "
                display: flex;
                justify-content: center;
              ",
              id = ns("qrcode")
            )
          )),
          h3(
            "Enter your two-factor authentication code"
          ),
          br(),
          div(
            style = "
              display: flex;
              justify-content: center;
            ",
            textInput(
              ns("two_fa_code"),
              label = NULL,
              value = ""
            ),
          ),
          br(),
          div(
            style = "
              display: flex;
              justify-content: center;
            ",
            actionLink(
              ns("sign_out"),
              "Return to sign in page"
            )
          )
        )
      )
    ),
    tags$script(src="https://cdn.rawgit.com/davidshimjs/qrcodejs/gh-pages/qrcode.min.js"),
    tags$script(src = "polish/js/two_fa_module.js?version=3"),
    tags$script(paste0("two_fa_module('", ns(''), "')"))
  )
}


#' Verify email page server logic
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny reactive observeEvent
#' @importFrom shinyFeedback showToast
#' @importFrom otp TOTP
#'
#' @noRd
#'
two_fa_module <- function(input, output, session) {

  two_fa_code <- reactive({

    out <- NULL
    tryCatch({
      req(session$userData$user()$user_uid)
      # TODO: add option to get the 2FA code to get_user
      hold <- get_users(
        user_uid = session$userData$user()$user_uid,
        include_two_fa = TRUE
      )

      out <- hold$content$two_fa_code

    }, error = function(err) {

      msg <- "unable to get 2FA code"
      print(msg)
      print(err)
      showToast("error", msg)

      invisible(NULL)
    })

    out
  })

  totp_obj <- reactiveVal(NULL)
  totp_secret <- reactiveVal("")
  observeEvent(two_fa_code(), {

    if (is.na(two_fa_code())) {
      # 2FA code has not been successfully verified and save to database, so create a
      # new secret
      base_32_secret <- paste(sample(c(LETTERS, 2:7), size = 16, replace = TRUE), collapse = "")
      shinyjs::showElement("qrcode_div")
    } else {
      base_32_secret <- two_fa_code()
    }
    totp_obj(otp::TOTP$new(base_32_secret))
    totp_secret(base_32_secret)

    # send the base 32 secret to the front end to generate the QR code using javascript
    session$sendCustomMessage(
      session$ns("create_qrcode"),
      message = list(
        "url" = utils::URLencode(paste0("otpauth://totp/", session$userData$user()$email, "?secret=", base_32_secret, "&issuer=", .polished$app_name))
      )
    )

  })



  observeEvent(input$two_fa_code, {
    hold_code <- input$two_fa_code
    hold_totp_obj <- totp_obj()
    hold_user <- session$userData$user()

    if (nchar(hold_code) == 6) {

      is_verified <- hold_totp_obj$verify(hold_code)

      if (!is.null(is_verified)) {

        tryCatch({
          # user entered the time password correctly.
          if (is.na(two_fa_code())) {

            update_user(
              user_uid = hold_user$user_uid,
              user_data = list(
                two_fa_code = totp_secret()
              )
            )

          }

          update_session(
            session_uid = hold_user$session_uid,
            session_data = list(
              two_fa_verified = TRUE
            )
          )

          session$reload()

        }, error = function(err) {

          msg <- "unable to verify 2FA code"
          print(msg)
          print(err)
          showToast("error", msg)

          invisible(NULL)
        })

      } else {
        showToast("error", "Invalid 2FA code")
      }

    }

  })

  observeEvent(input$sign_out, {

    tryCatch({
      sign_out_from_shiny()
      session$reload()
    }, error = function(err) {
      msg <- "error connecting to server"
      print(msg)
      print(err)
      showToast("error", msg)

      invisible(NULL)
    })

  })

}
