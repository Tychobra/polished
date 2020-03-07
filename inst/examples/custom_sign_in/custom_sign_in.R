fluidPage(
  tags$head(
    tags$title("App Name"),
    tags$link(rel = "shortcut icon", href = "polish/images/tychobra-icon-blue.png"),
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
        #submit_sign_in {
          background-color: #002f58;
          border-color: #002f58;
        }
      "
    ),

  ),
  fluidRow(
    column(
      12,
      img(
        width = "200px",
        src = "polish/images/tychobra_logo_blue_co_name.png",
        style = "margin-top: 15px;"
      )
    )
  ),
  fluidRow(
    style = "margin-bottom: 150px;",
    column(
      width = 5,
      offset = 2,
      style = "background-image: url('polish/images/workchat.svg');  background-repeat: no-repeat; background-size: contain; height: 550px",
      br(),
      br(),
      h1(
        style = "font-size: 72px;",
        "App Name"
      )
    ),
    column(
      width = 4,
      sign_in_module_ui(
        "sign_in",
        app_config$firebase
      )
    )
  ),
  fluidRow(
    style = "background-color: #002f58; color: white; margin-top: 15px;",
    column(
      12,
      style = "margin-top: 100px; margin-bottom: 100px;",
      fluidRow(
        style = "margin-bottom: 40px;",
        column(
          width = 3,
          offset = 2,
          h1("Track Data")
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
              h3(
                style = " line-height: 1.5;",
                "An intuitive web interface for keeping track of your data"
              )
            )
          )
        )
      ),

      fluidRow(
        style = "margin-bottom: 40px;",
        column(
          width = 3,
          offset = 2,
          h1("Analyze Trends")
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
              h3(
                style = " line-height: 1.5;",
                "More words here"
              )
            )
          )
        )
      ),


      fluidRow(
        style = "margin-bottom: 40px;",
        column(
          width = 3,
          offset = 2,
          h1("ML and AI")
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
              h3(
                style = " line-height: 1.5;",
                "Harness the statistical power of R"
              )
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
      p(
        HTML("&copy;"),
        "2020 - Tychobra"
      )
    )
  )
)
