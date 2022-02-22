

#' UI for the Social Sign In authentication providers' buttons
#'
#' Creates the HTML UI of the "Sign in with *" buttons.  These buttons are only
#' necessary if you enable Social Sign In via the \code{sign_in_providers} argument
#' passed to \code{\link{polished_config}}.
#'
#' @param ns the Shiny namespace function created with \code{shiny::NS()}.
#'
#' @inheritParams polished_config
#'
#' @param title The title to be used above the provider buttons. Set to \code{NULL} to not include
#' @param fancy Should the buttons be large and colorful?
#'
#' @importFrom htmltools tags
#' @importFrom shiny actionButton icon
#'
#' @export
#'
#' @return the HTML UI of the "Sign in with *" buttons.
#'
providers_ui <- function(
  ns,
  sign_in_providers = c(
    "google",
    "email"
  ),
  title = "Sign In",
  fancy = TRUE
) {

  if (isTRUE(fancy)) {
    providers_buttons <- list(
      "google" = shiny::actionButton(
        ns("sign_in_with_google"),
        "Sign in with Google",
        icon = shiny::icon("google"),
        width = "100%",
        class = "btn-lg",
        style = "background-color: #4285F4; color: #FFF; margin: 10px 0;"
      ),
      "microsoft" = shiny::actionButton(
        ns("sign_in_with_microsoft"),
        "Sign in with Microsoft",
        icon = shiny::icon("microsoft"),
        width = "100%",
        class = "btn-lg",
        style = "background-color: #7FBA00; color: #FFF; margin: 10px 0;"
      ),
      "facebook" = shiny::actionButton(
        ns("sign_in_with_facebook"),
        "Sign in with Facebook",
        icon = shiny::icon("facebook"),
        width = "100%",
        class = "btn-lg",
        style = "background-color: #3B5998; color: #FFF; margin: 10px 0;"
      ),
      "email" = shiny::actionButton(
        ns("sign_in_with_email"),
        "Sign in with Email",
        icon = shiny::icon("envelope"),
        width = "100%",
        class = "btn-lg",
        style = "background-color: #DB4437; color: #FFF; margin: 10px 0;"
      )
    )
  } else {
    providers_buttons <- list(
      "google" = shiny::actionButton(
        ns("sign_in_with_google"),
        "Sign in with Google",
        icon = shiny::icon("google"),
        width = "100%",
        style = "background-color: #e4e4e4; margin-bottom: 10px;"
      ),
      "microsoft" = shiny::actionButton(
        ns("sign_in_with_microsoft"),
        "Sign in with Microsoft",
        icon = shiny::icon("microsoft"),
        width = "100%",
        style = "background-color: #e4e4e4; margin-bottom: 10px;"
      ),
      "facebook" = shiny::actionButton(
        ns("sign_in_with_facebook"),
        "Sign in with Facebook",
        icon = shiny::icon("facebook"),
        width = "100%",
        style = "background-color: #e4e4e4; margin-bottom: 10px;"
      ),
      "email" = shiny::actionButton(
        ns("sign_in_with_email"),
        "Sign in with Email",
        icon = shiny::icon("envelope"),
        width = "100%",
        style = "background-color: #e4e4e4; margin-bottom: 10px;"
      )
    )
  }


  providers_out <- providers_buttons[sign_in_providers]

  if (is.null(title)) {
    htmltools::tags$div(
      id = ns("providers_ui"),
      providers_out,
      htmltools::tags$br(),
      htmltools::tags$br()
    )
  } else {
    htmltools::tags$div(
      id = ns("providers_ui"),
      htmltools::h1(
        class = "text-center",
        style = "padding-top: 0;",
        "Sign In"
      ),
      providers_out,
      htmltools::tags$br(),
      htmltools::tags$br()
    )
  }
}
