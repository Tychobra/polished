

header <- dashboardHeader(
  title = "Polished",
  polished::profile_module_ui("profile")
)

sidebar <- dashboardSidebar(
  disable = TRUE
)


body <- dashboardBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$script(src = "js/custom.js"),
    polished::firebase_dependencies(),
    polished::firebase_init(app_config$firebase)
  ),
  shinyjs::useShinyjs(),
  fluidRow(
    app_box_module_ui(
      id = "basic_insurer_dashboard",
      app_name = "Basic Insurer Dashboard",
      width = 6,
      img_src = "images/basic_insurer_dashboard.png",
      more_info = column(
        12,
        h4(
          style = "line-height: 1.25",
          "Basic Claims Analytics Dashboard."
        ),
        tags$ul(
          tags$li("View insurance claims at different points in time"),
          tags$li("Filter claims by state and claim status"),
          tags$li("Analyze frequency, severity, and changes in claim values over time"),
          tags$li("Download the claims for further analysis on your computer")
        )
      ),
      app_href = "https://apps.tychobra.com/t3_client"
    ),
    app_box_module_ui(
      id = "github_issues",
      app_name = "GitHub Issues",
      width = 6,
      img_src = "images/github_issues.png",
      more_info = column(
        12,
        h4(
          style = "line-height: 1.25",
          "Internal app for tracking issues on GitHub."
        ),
        tags$ul(
          tags$li("Contractors can see issues currenlty assigned to them"),
          tags$li("Displays total number of internal and client issues"),
          tags$li("Shows contractors the status and priorty of assigned issues")
        )
      ),
      app_href = "https://apps.tychobra.com/github_issues"
    )
  )
)

ui <- dashboardPage(
  header,
  sidebar,
  body,
  skin = "black"
)

secure_ui(
  ui,
  firebase_config = app_config$firebase,
  sign_in_page_ui = source("R/0_ui_sign_in.R", local = TRUE)$value
)

