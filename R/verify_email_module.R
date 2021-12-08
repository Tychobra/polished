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
#' @importFrom shiny observeEvent reactivePoll
#' @importFrom shinyFeedback showToast
#' @importFrom httr GET POST content status_code
#' @importFrom stats runif
#'
#' @noRd
#'
verify_email_module <- function(input, output, session) {


  ### check every 5 seconds if the user has verified their email address yet ---

  # the number of times that the API has been queried
  count_polls <- 0

  user_from_db <- shiny::reactivePoll(
    5000,
    session,
    checkFunc = function() {
      stats::runif(1)
    },
    valueFunc = function() {

      count_polls <<- count_polls + 1

      # only poll the API to continue checking if the user has verified their email
      # address for 8.33 minutes.  After 8.33 minutes, the user will need to refresh their
      # page after verifiying their email address.  This is to avoid users sitting on the
      # verification page and continuously pinging the API for no reason.
      if (count_polls < 100) {
        tryCatch({

          res <- httr::GET(
            url = paste0(getOption("polished")$api_url, "/users"),
            httr::authenticate(
              user = get_api_key(),
              password = ""
            ),
            query = list(
              user_uid = session$userData$user()$user_uid
            )
          )

          res_content <- jsonlite::fromJSON(
            httr::content(res, type = "text", encoding = "UTF-8")
          )

          if (identical(httr::status_code(res), 200L)) {
            return(res_content)
          } else {
            stop(res_content, call. = FALSE)
          }
        }, error = function(err) {

          print(err)

        })
      }

    }
  )

  shiny::observeEvent(user_from_db(), {
    hold_user <- user_from_db()

    if (isTRUE(hold_user$email_verified)) {
      session$reload()
    }
  })


  ### handle resending of verification email

  shiny::observeEvent(input$resend_verification_email, {

    tryCatch({
      hold_email <- session$userData$user()$email


      res <- httr::POST(
        url = paste0(getOption("polished")$api_url, "/resend-verification-email"),
        httr::authenticate(
          user = get_api_key(),
          password = ""
        ),
        body = list(
          email = hold_email,
          user_uid = session$userData$user()$user_uid,
          app_uid = getOption("polished")$app_uid
        ),
        encode = "json"
      )

      if (!identical(httr::status_code(res), 200L)) {
        res_content <- jsonlite::fromJSON(
          httr::content(res, type = "text", encoding = "UTF-8")
        )
        stop(res_content, call. = FALSE)
      }

      shinyFeedback::showToast(
        "success",
        paste0("Verification email send to ", hold_email),
        .options = polished_toast_options
      )
    }, error = function(err) {


      print("[polished] error - resending verification email")
      print(err)

      shinyFeedback::showToast(
        "error",
        "Error resending verification email",
        .options = polished_toast_options
      )
    })

  })

  # sign out triggered from JS
  shiny::observeEvent(input$sign_out, {
    sign_out_from_shiny(session)
    session$reload()
  })

}
