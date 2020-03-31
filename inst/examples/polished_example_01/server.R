server <- function(input, output, session) {

  output$secure_content <- renderPrint({
    session$userData$user()
  })


  observeEvent(input$sign_out, {

    sign_out_from_shiny(session)
    session$reload()

  })
}

secure_server(server)
