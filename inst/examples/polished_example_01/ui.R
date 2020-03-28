

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

secure_ui(ui)
