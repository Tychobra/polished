

ui <- fluidPage(
  fluidRow(
    column(
      6,
      h1("Polished Example 02"),
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

secure_ui(
  ui,
  sign_in_page_ui = sign_in_ui_default(
    sign_in_module_2_ui("sign_in")
  )
)

