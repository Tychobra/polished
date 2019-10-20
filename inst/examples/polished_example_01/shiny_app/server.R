server <- function(input, output, session) {

  output$secure_content <- renderPrint({
    session$userData$user()
  })

}

secure_server(server)
