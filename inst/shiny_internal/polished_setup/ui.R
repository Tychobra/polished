
header <- dashboardHeader(
  title = "Polished Admin"
)

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("Tab 2", tabName = "tab_2", icon = icon("balance-scale")),
    tags$div(
      style = "position: absolute; bottom: 0;",
      a(
        img(
          src = "https://res.cloudinary.com/dxqnb8xjb/image/upload/v1509563497/tychobra-logo-blue_dacbnz.svg",
          width = 50
        ),
        href = "https://tychobra.com/shiny"
      )
    )
  )
)

body <- dashboardBody(
  tags$head(
    #tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    #tags$script(src = "custom.js"),
    tags$link(rel="icon", href="https://res.cloudinary.com/dxqnb8xjb/image/upload/v1499450435/logo-blue_hnvtgb.png")
  ),
  tabItems(
    tabItem(
      tabName = "dashboard",
      fluidRow(
        column(
          width = 12,
          verbatimTextOutput("debuggin")
        )
      )
    ),
    tabItem(
      tabName = "tab_2",
      fluidRow(
        column(
          width = 12,
          h1("Tab 2")
        )
      )
    )
  )
)

dashboardPage(
  header,
  sidebar,
  body,
  skin = "black"
)
