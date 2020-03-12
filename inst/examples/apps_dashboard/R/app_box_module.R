#' app_box_module_ui
#'
#' @importFrom shiny NS tagList fluidRow column div h1 br tags a singleton
#' @importFrom shinydashboard box
#' @importFrom tychobratools flip_box
#'
#' @param id the module id
#' @param app_name the name of the app
#' @param img_src the image source.  Passed to the "src" attribute of the "img" html tag.
#' @param background_color the background color of the box
#'
#' @return app box UI
#'
app_box_module_ui <- function(
  id,
  app_name,
  img_src,
  more_info = "",
  width = 12,
  background_color = "#000",
  app_href = NULL
) {

  ns <- NS(id)
  tagList(
    box(
      width = width,
      style = paste0("background-color: ", background_color, "; color: #FFF;"),
      fluidRow(
        column(
          width = 12,
          tychobratools::flip_box(
            id = id,
            front_content = img(
              src = img_src,
              width = "100%",
              height = "380px",
              style = "border: 1px solid black"
            ),
            back_content = div(
              style = "border: 1px solid black; height: 380px; background-color: #FFFFFF; color: #000000;",
              h1(
                class = "text-center",
                "More Info"
              ),
              more_info
            )
          )
        )
      ),

      # background = background_color,
      fluidRow(
        column(
          width = 12,
          br(),
          tags$h2(
            app_name,
            style = "display: inline-block; margin-top: 0;"
          ),
          tags$a(
            style = "display: inline-block; color: white;",
            class = "btn btn-primary pull-right",
            id = ns("app_button_link"),
            href = app_href,
            target = 'blank_',
            "Live App"
          ) %>% shinyjs::disabled(),
          div(
            id = ns("go_to_back"),
            class = "pull-right",
            style = "display: inline-block; margin-right: 5px;",
            tychobratools::flip_button_front(id, "More Info")
          ),
          div(
            id = ns("go_to_front"),
            class = "pull-right",
            style = "display: none; margin-right: 5px;",
            tychobratools::flip_button_back(id, "App Image")
          )
        )
      )
    ),
    shiny::singleton(
      tags$script(src = "js/app_box_module.js")
    ),
    tags$script(sprintf("app_box_module_js('%s')", id)),
  )

}

#' app_box_module
#'
#' @importFrom shiny observe
#' @importFrom shinyjs enable
#'
#' @param app_id the id of the app
#' @param user_apps Reactive value(s) of app names (id's) the current Shiny user is authorized to use
#'
#' @return Enable/Disable the "Live App" button in the `app_box_module_ui`
#'
app_box_module <- function(input, output, session,
  app_id,
  user_apps
) {

  ns <- session$ns

  # enable/disable the "Live App" button depending on if the user has access to
  # the app
  observe({
    if (app_id %in% user_apps()) {
      shinyjs::enable(id = "app_button_link")
    }
  })

}



