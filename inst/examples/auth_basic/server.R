server <- function(input, output, session) {

  output$secure_content <- renderPrint({
    "this is sensitive info"
  })

}

secure_server(
  server,
  firebase_functions_url = my_config$firebase_functions_url,
  app_name = my_config$app_name
)
