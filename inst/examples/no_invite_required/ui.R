

ui <- fluidPage(
  fluidRow(
    column(
      12,
      h1("Polished Example 01"),
      br()
    ),
    column(
      12,
      verbatimTextOutput("secure_content")
    )
  )
)

secure_ui(
  ui,
  sign_in_page_ui = sign_in_no_invite_module_ui("sign_in")
)
