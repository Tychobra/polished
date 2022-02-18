server <- function(input, output, session) {

  output$secure_content <- renderPrint({
    session$user()
  })


  observeEvent(input$sign_out, {

    tryCatch({

      sign_out_from_shiny(session)
      session$reload()

    }, error = function(err) {

      msg <- "unable to sign out"
      print(msg)
      print(err)

    })

  })

}

secure_server(server)
