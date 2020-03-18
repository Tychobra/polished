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
  
  callModule(
    app_box_module,
    id = "basic_insurer_dashboard",
    app_id = "basic_insurer_dashboard",
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
