

#' providers_ui
#'
#' Creates the html UI of the "Sign in with *" buttons.
#'
#' @param ns the 'shiny' namespce function created with \code{shiny::NS()}.
#'
#' @inheritParams global_sessions_config
#'
#' @export
#'
#' @return the html UI of the "Sign in with *" buttons.
#'
providers_ui <- function(ns, sign_in_providers = c(
  "google",
  "email"
)) {

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


  providers_out <- providers_buttons[sign_in_providers]


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