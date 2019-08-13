

ui <- fluidPage(
  fluidRow(
    style = "color: white; background-color: black; height: 100vh;",
    column(
      12,
      fluidRow(
        column(
          9,
          h1("Shiny App")
        ),
        column(
          3,
          class = "pull-right",
          style = "background-color: #0277BD; color: black; height: 198px;",
          h3(
            class = "text-center",
            style = "color: white; margin-bottom: 0",
            "Signed In As"
          ),
          DTOutput("user_table"),
          br()
        )
      ),
      br()
    ),
    column(
      12,
      class = "text-center",
      h1(
        style = "font-size: 90px;",
        "Your Custom"
      ),
      h1(
        style = "font-size: 90px;",
        "Shiny App"
      ),
      br(),
      br()
    )
  )
)


secure_ui(
  ui,
  firebase_config = my_config$firebase,
  app_name = my_config$app_name,
  sign_in_page_ui = source("polished/custom_sign_in_page.R", local = TRUE)$value
)
