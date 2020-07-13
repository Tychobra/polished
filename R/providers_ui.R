

#' UI for the Firebase authentication providers buttons
#'
#' Creates the html UI of the "Sign in with *" buttons.  These buttons are only
#' necessary if you enable social sign in via the \code{sign_in_providers} argument
#' passed to \code{\link{global_sessions_config}}.
#'
#' @param ns the 'shiny' namespace function created with \code{shiny::NS()}.
#'
#' @inheritParams global_sessions_config
#' 
#' @param title The title to be used above the provider buttons. Set to NULL to not include
#' @param fancy Should the buttons be large and colorful?
#'
#' @export
#'
#' @return the html UI of the "Sign in with *" buttons.
#'
providers_ui <- function(ns, sign_in_providers = c(
  "google",
  "email"
), title = "Sign In", fancy = TRUE) {

  if(isTRUE(fancy)) {
    providers_buttons <- list(
      "google" = actionButton(
        ns("sign_in_with_google"),
        "Sign in with Google",
        icon = icon("google"),
        width = "100%",
        class = "btn-lg",
        style = "background-color: #4285F4; color: #FFF; margin: 10px 0;"
      ),
      "microsoft" = actionButton(
        ns("sign_in_with_microsoft"),
        "Sign in with Microsoft",
        icon = icon("microsoft"),
        width = "100%",
        class = "btn-lg",
        style = "background-color: #7FBA00; color: #FFF; margin: 10px 0;"
      ),
      "facebook" = actionButton(
        ns("sign_in_with_facebook"),
        "Sign in with Facebook",
        icon = icon("facebook"),
        width = "100%",
        class = "btn-lg",
        style = "background-color: #3B5998; color: #FFF; margin: 10px 0;"
      ),
      "email" = actionButton(
        ns("sign_in_with_email"),
        "Sign in with Email",
        icon = icon("envelope"),
        width = "100%",
        class = "btn-lg",
        style = "background-color: #DB4437; color: #FFF; margin: 10px 0;"
      )
    )
  } else {
    providers_buttons <- list(
      "google" = actionButton(
        ns("sign_in_with_google"),
        "Sign in with Google",
        icon = icon("google"),
        width = "100%",
        style = "background-color: #e4e4e4; margin-bottom: 10px;"
      ),
      "microsoft" = actionButton(
        ns("sign_in_with_microsoft"),
        "Sign in with Microsoft",
        icon = icon("microsoft"),
        width = "100%",
        style = "background-color: #e4e4e4; margin-bottom: 10px;"
      ),
      "facebook" = actionButton(
        ns("sign_in_with_facebook"),
        "Sign in with Facebook",
        icon = icon("facebook"),
        width = "100%",
        style = "background-color: #e4e4e4; margin-bottom: 10px;"
      ),
      "email" = actionButton(
        ns("sign_in_with_email"),
        "Sign in with Email",
        icon = icon("envelope"),
        width = "100%",
        style = "background-color: #e4e4e4; margin-bottom: 10px;"
      )
    )
  }


  providers_out <- providers_buttons[sign_in_providers]

  if (is.null(title)) {
    tags$div(
      id = ns("providers_ui"),
      providers_out,
      br(),
      br()
    )
  } else {
    tags$div(
      id = ns("providers_ui"),
      htmltools::h1(
        class = "text-center",
        style = "padding-top: 0;",
        "Sign In"
      ),
      providers_out,
      br(),
      br()
    )
  }
}