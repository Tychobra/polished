server <- function(input, output, session) {

  output$secure_content <- renderPrint({
    session$userData$user()
  })


  observeEvent(input$sign_out, {

    tryCatch({

      sign_out_from_shiny(session)
      session$reload()

    }, error = function(err) {

      msg <- "unable to sign out"
      warning(msg)
      warning(conditionMessage(err))

      invisible(NULL)
    })

  })

}

secure_server(server)
