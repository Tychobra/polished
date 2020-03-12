server <- function(input, output, session) {

  # get all users for all apps
  user_apps <- reactive({
    polished::get_app_users(db_conn) %>%
      filter(user_uid == session$userData$user()$user_uid) %>%
      pull(app_name)

  })


  callModule(
    polished::profile_module,
    "profile"
  )

  token <- reactive({
    input$firebase_token
  })

  # callModule(
  #   app_box_module,
  #   id = "track",
  #   app_id = "track",
  #   user_apps = user_apps,
  #   app_href = "https://tychobra.shinyapps.io/track",
  #   firebase_token = token
  # )

  callModule(
    app_box_module,
    id = "custom_sign_in",
    app_id = "custom_sign_in",
    user_apps = user_apps
  )

  callModule(
    app_box_module,
    id = "github_issues",
    app_id = "github_issues",
    user_apps = user_apps
  )

}

secure_server(server)
