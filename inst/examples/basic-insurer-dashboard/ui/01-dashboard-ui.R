tabItem(
  "dashboard",
  fluidRow(
    column(
      width = 9,
      fluidRow(
        valueBoxOutput("paid_box"),
        valueBoxOutput("case_box"),
        valueBoxOutput("reported_box")
      ),
      fluidRow(
        box(
          width = 12,
          apexchartOutput(
            "ay_plot",
            height = 500
          )
          # highchartOutput(
          #   "ay_plot",
          #   height = 500
          # )
        )#,
        #verbatimTextOutput("debuggin")
      )
    ),
    box(
      width = 3,
      title = "Loss Metric",
      div(
        class = "text-center",
        radioButtons(
          "dash_metric",
          label = NULL,
          choices = c("Total" = "total", 
                      "Severity" = "severity",
                      "Claims" = "claims"),
          inline = TRUE
        )
      )
    ),
    box(
      width = 3,
      title = "Data Filters",
      conditionalPanel(
        "input.dash_metric !== 'claims'",
        div(
          class = "text-center",
          checkboxGroupInput(
            "dash_status",
            "Status",
            choices = c("Open", "Closed"),
            selected = c("Open", "Closed"),
            inline = TRUE
          ),
          br()
        )
      ),
      numericInput(
        "dash_cutoff",
        "Exclude claims if Reported below:",
        value = 0,
        min = 0
      ),
      br(),
      shinyWidgets::pickerInput(
        inputId = "dash_state", 
        label = "State", 
        choices = state_choices, 
        options = list(`actions-box` = TRUE), 
        multiple = TRUE,
        selected = state_choices
      ),
      br()
    )
  )
)
