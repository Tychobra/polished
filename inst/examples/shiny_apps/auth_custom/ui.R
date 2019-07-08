

ui <- fluidPage(
  useShinyjs(),
  fluidRow(
    column(
      12,
      h1("Title"),
      br()
    ),
    column(
      12,
      verbatimTextOutput("secure_content")
    )
  )
)

secure_ui(
  ui,
  firebase_config = my_config$firebase,
  app_name = my_config$app_name,
  sign_in_page_ui = fluidPage(
    tags$head(
      tags$style("
        .auth_panel {
          width: 350px;
          max-width: 100%;
          margin: 0 auto;
          border: 2px solid #eee;
          border-radius: 25px;
          padding: 30px;
          background: #f9f9f9;
        }
      ")
    ),
    fluidRow(
      column(
        12,
        img(
          width = "300px",
          src = "https://res.cloudinary.com/dxqnb8xjb/image/upload/v1533565833/tychobra_logo_blue_co_name_jekv4a.png"
        )
      )
    ),
    fluidRow(
      column(
        width = 5,
        offset = 2,
        br(),
        br(),
        h1(
          style = "font-size: 72px;",
          "App Name"
        ),
        p(
          style = "font-size: 54px;",
          "Tychobra"
        )
      ),
      column(
        width = 4,
        sign_in_ui(my_config$firebase)
      )
    )
  )
)
