library(shinydashboard)

tabItem(
  tabName = "custom_tab",
  h1("My Custom Tab"),
  verbatimTextOutput("custom_out")
)
