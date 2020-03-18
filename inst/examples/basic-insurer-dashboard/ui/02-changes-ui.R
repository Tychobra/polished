tabItem(
  tabName = "changes",
  fluidRow(
    box(
      width = 9,
      div(
        style = "text-align: center;",
        h2("All Claims with Changes in Paid or Reported"),
        h3(textOutput("changes_title"))
      ),
      DTOutput("changes_tbl")
    ),
    box(
      width = 3,
      title = "Filters",
      dateInput(
        "val_date_prior", 
        "Prior Valuation Date",
        value = Sys.Date() - lubridate::years(1),
        min = min(trans$accident_date),
        max = Sys.Date(),
        startview = "decade"
      ),
      checkboxGroupButtons(
        "changes_new",
        "Claim Type",
        choices = c("New", "Existing"),
        selected = c("New", "Existing"),
        justified = TRUE,
        status = "primary",
        checkIcon = list(
          yes = icon("ok", lib = "glyphicon"), 
          no = icon("remove", lib = "glyphicon")
        )
      ),
      br(),
      shinyWidgets::pickerInput(
        inputId = "changes_ay", 
        label = "Accident Year", 
        choices = ay_choices, 
        options = list(`actions-box` = TRUE), 
        multiple = TRUE,
        selected = ay_choices
      )
    )
  )
)
