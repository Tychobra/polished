

ui <- fluidPage(
  fluidRow(
    column(
      12,
      h1("Title"),
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
  firebase_config = app_config$firebase
)
