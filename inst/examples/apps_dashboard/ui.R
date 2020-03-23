

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
      app_name = "Basic Claims Analytics Dashboard",
      width = 6,
      img_src = "images/basic_insurer_dashboard.png",
      more_info = column(
        12,
        h4(
          style = "line-height: 1.25",
          "Basic Claims Analytics Dashboard"
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
      id = "interest_rate_walk",
      app_name = "Interest Rate Walk",
      width = 6,
      img_src = "images/interest_rate_walk_dashboard.png",
      more_info = column(
        12,
        h4(
          style = "line-height: 1.25",
          "Interest Rate Walk Dashboard"
        ),
        tags$ul(
          tags$li("View visualizations and tables with interest rate data over time"),
          tags$li("Run a Cox-Ingersoll-Ross random walk or a bootstrap resampling of treasury yield changes"),
          tags$li("View historical treasury yields to reference for parameter selection during resampling")
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

