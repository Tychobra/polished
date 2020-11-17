

ui <- fluidPage(
  shinyjs::useShinyjs(),
  fluidRow(
    column(
      6,
      h1("Polished Example 04 - Sentry"),
      br()
    ),
    column(
      6,
      br(),
      shinyjs::hidden(actionButton(
        "sign_out",
        "Sign Out",
        icon = icon("sign-out-alt"),
        class = "pull-right"
      )),
      shinyjs::hidden(actionButton(
        "go_to_sign_in",
        "Sign In",
        icon = icon("sign-in-alt"),
        class = "pull-right"
      )),
      actionButton(
        "throw_js_error",
        "Throw JS Error"
      )
    ),
    column(
      12,
      verbatimTextOutput("secure_content")
    ),
    tags$script("
      $(document).on('click', '#throw_js_error', function() {
        throw new Error('js error')
      })
    ")
  )
)

secure_ui(ui)
