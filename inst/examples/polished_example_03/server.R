server <- function(input, output, session) {

  output$secure_content <- renderPrint({
    session$userData$user()
  })

  observe({

    if (is.null(session$userData$user())) {

      hideElement("sign_out")
      showElement("go_to_sign_in")

    } else {

      hideElement("go_to_sign_in")
      showElement("sign_out")

    }

  })

  observeEvent(input$sign_out, {
    req(session$userData$user())

    sign_out_from_shiny(session)
    session$reload()

  })

  observeEvent(input$go_to_sign_in, {

    # set query string to sign in page
    shiny::updateQueryString(
      queryString = paste0("?page=sign_in"),
      session = session,
      mode = "push"
    )
    session$reload()
  })

}

secure_server(server)
