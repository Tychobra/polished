fluidPage(
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
      width = 12,
      style = " margin-bottom: 50px;",
      img(
        width = "300px",
        src = "https://res.cloudinary.com/dxqnb8xjb/image/upload/v1533565833/tychobra_logo_blue_co_name_jekv4a.png"
      )
    )
  ),
  fluidRow(
    style = "margin-bottom: 100px;",
    column(
      width = 6,
      offset = 1,
      style = "background-image: url('polish/images/workchat.svg');  background-repeat: no-repeat; background-size: contain; height: 550px;",
      br(),
      br(),
      h1(
        style = "font-size: 72px;",
        "App Name"
      )
    ),
    column(
      width = 4,
      sign_in_ui(my_config$firebase)
    )
  ),
  fluidRow(
    style = "background-color: #0277BD; color: white; margin-top: 15px;",
    column(
      12,
      style = "margin-top: 100px; margin-bottom: 100px;",
      fluidRow(
        style = "margin-bottom: 40px;",
        column(
          width = 3,
          offset = 2,
          h1("Cool Functionality")
        ),
        column(
          5,
          style = "background-color: white; border-radius: 8px;",
          fluidRow(
            style = "margin-bottom: 15px; margin-top: 15px;",
            column(
              5,
              tags$img(
                src = "polish/images/landing-page.svg",
                width = "100%"
              )
            ),
            column(
              7,
              style = "color: black;",
              h3("Description of Functionality")
            )
          )
        )
      ),

      fluidRow(
        style = "margin-bottom: 40px;",
        column(
          width = 3,
          offset = 2,
          h1("More Cool Functionality")
        ),
        column(
          5,
          style = "background-color: white; border-radius: 8px;",
          fluidRow(
            style = "margin-bottom: 15px; margin-top: 15px;",
            column(
              5,
              tags$img(
                src = "polish/images/data-analytics.svg",
                width = "100%"
              )
            ),
            column(
              7,
              style = "color: black;",
              h3("Description of Functionality")
            )
          )
        )
      ),


      fluidRow(
        style = "margin-bottom: 40px;",
        column(
          width = 3,
          offset = 2,
          h1("Even More Cool Functionality!!")
        ),
        column(
          5,
          style = "background-color: white; border-radius: 8px;",
          fluidRow(
            style = "margin-bottom: 15px; margin-top: 15px;",
            column(
              5,
              tags$img(
                src = "polish/images/in-progress.svg",
                width = "100%"
              )
            ),
            column(
              7,
              style = "color: black;",
              h3("Description of Functionality")
            )
          )
        )
      )

    )
  ),


  fluidRow(
    column(
      12,
      class = "text-center",
      style = "margin-top: 150px; margin-bottom: 5px",
      p("Footer")
    )
  )
)
