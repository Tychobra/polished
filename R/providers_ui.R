

#' @noRd
providers_ui <- function(ns) {
  tags$div(
    id = ns("providers_ui"),
    htmltools::h1(
      class = "text-center",
      style = "padding-top: 0;",
      "Sign In"
    ),
    br(),
    br(),
    actionButton(
      ns("sign_in_with_google"),
      "Sign in with Google",
      icon = icon("google"),
      width = "100%",
      class = "btn-lg",
      style = "background-color: #4285F4; color: #FFF"
    ),
    # br(),
    # br(),
    # actionButton(
    #   ns("sign_in_with_microsoft"),
    #   "Sign in with Microsoft",
    #   icon = icon("microsoft"),
    #   width = "100%",
    #   style = "background-color: #7FBA00; color: #FFF"
    # ),
    br(),
    br(),
    actionButton(
      ns("sign_in_with_email"),
      "Sign in with Email",
      icon = icon("envelope"),
      width = "100%",
      class = "btn-lg",
      style = "background-color: #DB4437; color: #FFF;"
    ),
    br(),
    br(),
    br()
  )
}