server <- function(input, output, session) {

  output$secure_content <- renderPrint({
    session$userData$user()
  })


  observeEvent(input$sign_out, {

    sign_out_from_shiny(session)
    session$reload()

  })

  output$test_render <- renderUI({

    session$userData$user()

  })

}

secure_server(server)
