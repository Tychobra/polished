

ui <- fluidPage(
  tags$head(
    tags$link(rel="manifest", href="/manifest.json"),
    tags$link(rel="apple-touch-icon", href="/icon-192x192.png"),
    tags$link(name="apple-mobile-web-app-capable", content="yes")
  ),
  fluidRow(
    column(
      6,
      h1("Polished Example 01"),
      br()
    ),
    column(
      6,
      br(),
      actionButton(
        "sign_out",
        "Sign Out",
        icon = icon("sign-out-alt"),
        class = "pull-right"
      )
    ),
    column(
      12,
      verbatimTextOutput("secure_content")
    )
  ),
  tags$script(src = "app.js")
)


ui_out <- secure_ui(ui)


ui_func <- function(request) {

  query_list <- shiny::parseQueryString(request$QUERY_STRING)
  if (!is.null(query_list$stay_alive)) {

    out <- httpResponse(
      status = 200L,
      content_type = "application/json",
      content = jsonlite::toJSON(list(message = "success"), auto_unbox = TRUE, na = "null")
    )

  } else {
    out <- ui_out(request)
  }

  out
}

attr(ui_func, "http_methods_supported") <- c("GET", "POST")

ui_func
