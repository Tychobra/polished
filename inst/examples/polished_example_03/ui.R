

ui <- fluidPage(
  shinyjs::useShinyjs(),
  fluidRow(
    column(
      6,
      h1("Polished Example 03"),
      br()
    ),
    column(
      6,
      br(),
      shinyjs::hidden(actionButton(
        "sign_out",
        "Sign Out",
        icon = icon("sign-out-alt"),
        class = "pull-right"
      )),
      shinyjs::hidden(actionButton(
        "go_to_sign_in",
        "Sign In",
        icon = icon("sign-in-alt"),
        class = "pull-right"
      ))
    ),
    column(
      12,
      verbatimTextOutput("secure_content")
    )
  )
)

secure_ui(ui)
