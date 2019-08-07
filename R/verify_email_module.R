#' verify email page ui
#'
#' @param firebase_config Firebase configuration
#'
#' @export
verify_email_ui <- function(id, firebase_config) {
  ns <- NS(id)

  fluidPage(
    tags$head(
      tags$link(rel = "stylesheet", href = "polish/css/all.css"),
      tags$link(rel = "shortcut icon", href = "polish/images/tychobra-icon-blue.png"),
      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.js"),
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.css")
    ),
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
    tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
    firebase_init(firebase_config),
    tags$script(src = "polish/js/all.js"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    tags$script(src = "polish/js/auth-state.js"),
    tags$script(src = "polish/js/verify_email.js")
  )
}


