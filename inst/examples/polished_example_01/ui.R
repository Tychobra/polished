

ui <- fluidPage(
  fluidRow(
    column(
      6,
      h1("Polished Example 01"),
      br()
    ),
    column(
      6,
      br(),
      actionButton(
        "sign_out",
        "Sign Out",
        icon = icon("sign-out-alt"),
        class = "pull-right"
      )
    ),
    column(
      12,
      verbatimTextOutput("secure_content")
    )
  )
)

secure_ui(ui)
