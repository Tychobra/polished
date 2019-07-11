function(input, output, session) {
  session <- secure_server(
    input,
    session,
    firebase_functions_url = my_config$firebase_functions_url,
    app_name = my_config$app_name
  )



  #source("server_admin.R", local = TRUE)

  # observe({
  #   print(list(
  #     "current_user" = session$userData$current_user()
  #   ))
  # })

  observeEvent(session$userData$current_user(), {

    output$secure_content <- renderPrint({
      "this is sensitive info"
    })

  })
}
