fluidPage(
  theme = shinytheme("flatly"),
  # Application title
  tags$head(
    tags$link(
      rel="icon",
      href="https://res.cloudinary.com/dxqnb8xjb/image/upload/v1509563497/tychobra-logo-blue_dacbnz.svg"
    )
  ),
  fluidRow(
    headerPanel(
      tags$div(
        a(
          img(
            src = "https://res.cloudinary.com/dxqnb8xjb/image/upload/v1509563497/tychobra-logo-blue_dacbnz.svg", 
            width = 50
          ), 
          href = "https://tychobra.com/shiny"
        ),
        h1("Interest Rate Walk", style = "display: inline"),
        a(
          href = "https://github.com/Tychobra/shiny-insurance-examples/tree/master/interest-rate-walk",
          icon("github", class="fa-lg pull-right")
        )
      ), 
      windowTitle = "Interest Rate"
    )
  ),
  br(),
  fluidRow(
    column(
      width = 3,
      class = "text-center",
      wellPanel(
        h3("General Simulation Parameters"),
        br(),
        fluidRow(
          column(
            width = 6,
            sliderInput(
              "num_years",
              "Num Years",
              min = 1,
              max = 30,
              value = 30,
              ticks = FALSE
            )
          ),
          column(
            width = 6,
            sliderInput(
              "num_obs",
              "Num Observations",
              min = 1,
              max = 10,
              value = 10,
              ticks = FALSE
            )
          )
        ),
        br(),
        radioButtons(
          inputId = "type",
          label = "Type of Walk",
          choices = c(
            "Cox-Ingersoll-Ross" = "cir",
            "Bootstrap Resampling" = "bootstrap"
          ),
          inline = TRUE,
          selected = "bootstrap"
        ),
        br(),
        hr(style = "border-top: 1px solid #000"),
        conditionalPanel(
          'input.type == "cir"',
          h3("Cox-Ingersoll-Ross Parameters"),
          br(),
          numericInput(
            inputId = "reversion",
            label = "Mean Reversion Speed - a",
            value = 1,
            step = 0.1
          ),
          numericInput(
            inputId = "ir_mean",
            label = "Interst Rate Mean - b",
            value = 4,
            step = 0.1
          ),
          numericInput(
            inputId = "ir_sd",
            label = "Interest Rate SD - sigma",
            value = 2,
            step = 0.1
          )
        ),
        conditionalPanel(
          'input.type == "bootstrap"',
          h3("Bootstrap Resampling Using Treasury Yields"),
          br(),
          numericInput(
            inputId = "bs_yield",
            label = "Initial Yield (yield at year 0)",
            value = 4,
            step = 0.1
          ),
          selectInput(
            inputId = "duration",
            label = "Treasury Duration",
            choices = c(
              "1 Year" = "t_1",
              "5 Year" = "t_5",
              "10 Year" = "t_10",
              "20 Year" = "t_20",
              "30 Year" = "t_30"
            ),
            selected = "t_10"
          ),
          sliderInput(
            inputId = "sample_years",
            label = "Sample Years",
            min = year_min,
            max = year_max,
            value = c(year_min, year_max),
            ticks = FALSE,
            sep = ""
          )
        )
      )
    ),
    column(
      width = 9,
      tabsetPanel(
        tabPanel(
          "Plot",
          br(),
          highchartOutput("sims_chart", height = 600)
        ),
        tabPanel(
          "Table",
          br(),
          DT::dataTableOutput("sim_tbl")
        )
      )
    )
  ),
  fluidRow(
    column(
      width = 12,
      class = "text-center",
      br(),
      br(),
      hr(),
      h1("Historical Treasury Yields"),
      h3("(For Your Reference in Making Parameter Selections in Above Walk)"),
      br()
    )
  ),
  fluidRow(
    column(
      width = 6,
      wellPanel(
        DT::dataTableOutput("ir_tbl")
      )
    ),
    column(
      width = 6,
      wellPanel(
        highchartOutput("ir_chart", height = 500)
      )
    )
  )
)