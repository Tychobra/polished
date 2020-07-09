#' Secure a static html page
#'
#' \code{secure_static()} can be used to secure any html
#' page using 'polished'.  It is often used to add 'polished' to ".Rmd" htmloutput
#' and flexdashboards.
#'
#' @param html_file_path the path the to html file.  See the details for more info.
#' @param global_sessions_config_args arguments to be passed to \code{\link{global_sessions_config}}.
#'
#' @md
#'
#' @details To secure a static html page, place the html page in a folder named "www"
#' and call \code{secure_static()} from a file named "app.R".  The file structure should
#' look like:
#'
#' - app.R
#' - www/
#'   - index.html
#'
#' See an example here: \url{https://github.com/Tychobra/polished_example_apps/tree/master/05_flex_dashboard}
#'
#' @export
#'
#' @return a Shiny app object
#'
#' @importFrom shiny shinyApp actionButton
#' @importFrom htmltools tags tagList
#'
secure_static <- function(html_file_path, global_sessions_config_args) {

  ui <- htmltools::tagList(
    tags$head(
      tags$style("
      body {
        margin: 0;
        padding: 0;
        overflow: hidden
      }
    "),
    ),
    tags$iframe(
      src = html_file_path,
      height = "100%",
      width = "100%",
      style="height: 100%; width: 100%; overflow: hidden; position: absolute; top:0; left: 0; right: 0; bottom:0",
      frameborder="0"
    )
  )

  ui <- secure_ui(
    ui,
    custom_admin_button_ui = shiny::actionButton(
      "polished-go_to_admin_panel",
      "Admin Panel",
      icon = shiny::icon("cog"),
      style = "position: fixed; bottom: 15px; right: 15px; color: #FFFFFF; z-index: 9999; background-color: #0000FF; padding: 15px;"
    )
  )

  server <- secure_server(function(input, output, session) {
    observeEvent(input$sign_out, {
      sign_out_from_shiny(session)
      session$reload()
    })
  })


  shiny::shinyApp(ui, server, onStart = function() {
    library(polished)

    # configure the global sessions when the app initially starts up.
    do.call(
      "global_sessions_config",
      global_sessions_config_args
    )
  })
}
