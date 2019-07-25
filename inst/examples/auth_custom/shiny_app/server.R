function(input, output, session) {
  session <- secure_server(
    input,
    session,
    firebase_functions_url = my_config$firebase_functions_url,
    app_name = my_config$app_name
  )


  observeEvent(session$userData$current_user(), {

    output$secure_content <- renderPrint({
      session$userData$current_user()[c("email", "is_admin", "role")]
    })

    user_table_prep <- reactive({

      data.frame(
        "key" = c("email", "is_admin", "role"),
        "value" = unname(unlist(session$userData$current_user()[c("email", "is_admin", "role")]))
      )
    })

    observe({
      print(list(
        user_table_prep = user_table_prep()
      ))
    })

    output$user_table <- renderDT({

      datatable(
        user_table_prep(),
        rownames = FALSE,
        class = "display cell-border",
        colnames = c("", ""),
        options = list(
          dom = "t",
          ordering = FALSE,
          columnDefs = list(
            list(targets = 1, class = "dt-right")
          )
        )
      )

    })

  })
}
