

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
          verbatimTextOutput("secure_content")
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
  ),
  tags$script(src="https://unpkg.com/pts/dist/pts.min.js"),
  tags$script(src = "pt_bezier.js")
)


secure_ui(
  ui,
  firebase_config = my_config$firebase,
  app_name = my_config$app_name,
  sign_in_page_ui = source("polished/custom_sign_in_page.R", local = TRUE)$value
)
