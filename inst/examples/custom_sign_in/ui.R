

ui <- fluidPage(
  fluidRow(
    column(
      12,
      h1("Custom Sign In Example"),
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
  sign_in_page_ui = source("custom_sign_in.R", local = TRUE)$value
)
