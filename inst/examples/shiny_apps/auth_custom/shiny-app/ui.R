

ui <- fluidPage(
  useShinyjs(),
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
  firebase_config = my_config$firebase,
  app_name = my_config$app_name,
  sign_in_page_ui = source("polished/custom_sign_in_page.R", local = TRUE)$value
)
