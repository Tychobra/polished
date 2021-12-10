#' Render and secure Rmarkdown document
#'
#' \code{secure_render()} can be used to render and secure any Rmarkdown document.
#' Rendering is handled by \code{rmarkdown::render} and the then the rendered document
#' is secured with \code{polished} authentication.
#'
#' @param rmd_file_path the path the to .Rmd file.
#' @param global_sessions_config_args arguments to be passed to \code{\link{global_sessions_config}}.
#' @param sign_out_button action button or link with \code{inputId = "sign_out"}. Set to \code{NULL} to not include a sign out button.
#'
#' @md
#'
#' @export
#'
#' @return a Shiny app object
#'
#' @importFrom shiny shinyApp actionLink addResourcePath
#' @importFrom htmltools tags tagList includeHTML
#' @importFrom rmarkdown render run
#' @importFrom callr r_session
#'
#'
#' @examples
#'
#' \dontrun{
#'
#' secure_render("inst/examples/rmds/flexdashboard.Rmd")
#' secure_render("inst/examples/rmds/flexdashboard_shiny.Rmd")
#' secure_render("inst/examples/rmds/html_document.Rmd")
#' secure_render("inst/examples/rmds/pdf_document.Rmd")
#' }
secure_render <- function(
  rmd_file_path,
  global_sessions_config_args = list(
    api_key = get_api_key()
  ),
  sign_in_page_args = list(),
  sign_out_button = shiny::actionLink(
    "sign_out",
    "Sign Out",
    icon = shiny::icon("sign-out-alt"),
    class = "polished_sign_out_link"
  )) {

  yaml_header <- yamlFromRmd(rmd_file_path)

  yaml_polished <- yaml_header$polished

  if (is.null(yaml_polished)) {
    stop('"polished" must be included in the YAML header', call. = FALSE)
  }

  global_sessions_config_args <- modifyList(
    global_sessions_config_args,
    yaml_header$polished$global_sessions_config
  )

  if (is.null(global_sessions_config_args$app_name)) {
    stop('polished "app_name" must be provided', call. = FALSE)
  }
  if (is.null(global_sessions_config_args$api_key)) {
    stop('polished "api_key" must be provided', call. = FALSE)
  }

  do.call(
    global_sessions_config,
    global_sessions_config_args
  )

  if (!is.null(yaml_polished$sign_in_page)) {
    sign_in_page_args <- modifyList(
      sign_in_page_args,
      yaml_polished$sign_in_page
    )
  }





  if (!is.null(yaml_header$runtime) && yaml_header$runtime %in% c("shiny", "shinyrmd", "shiny_prerendered")) {
    # runtime = shiny

    rs <- callr::r_session$new()
    rs$call(
      function(rmd_path) {
        rmarkdown::run(file = rmd_path, shiny_args = list(port = 8241, launch.browser = FALSE))
      },
      args = list(
        rmd_file_path
      )
    )


    embeded_app <- tags$iframe(
      src = "http://127.0.0.1:8241",
      height = "100%",
      width = "100%",
      style="height: 100%; width: 100%; overflow: hidden; position: absolute; top:0; left: 0; right: 0; bottom:0",
      frameborder="0"
    )

  } else {
    # static (non shiny) document (html or pdf)

    static_file_path <- rmarkdown::render(rmd_file_path)

    static_file_name <- basename(static_file_path)
    shiny::addResourcePath("polished_static", dirname(static_file_path))

    embeded_app <- tags$iframe(
      src = file.path("polished_static", static_file_name),
      height = "100%",
      width = "100%",
      style="height: 100%; width: 100%; overflow: hidden; position: absolute; top:0; left: 0; right: 0; bottom:0",
      frameborder="0"
    )
  }



  ui <- htmltools::tagList(
    sign_out_button,
    tags$head(
      tags$style("
      body {
        margin: 0;
        padding: 0;
        overflow: hidden
      }

      .polished_sign_out_link {
        font-family: 'Source Sans Pro',Calibri,Candara,Arial,sans-serif;
        position: absolute;
        top: 0;
        right: 15px;
        color: #FFFFFF;
        z-index: 9999;
        padding: 15px;
        text-decoration: none;
      }
    "),
    ),
    embeded_app
  )

  secure_ui_args <- list(
    ui = ui,
    custom_admin_button_ui = shiny::actionButton(
      "polished-go_to_admin_panel",
      "Admin Panel",
      icon = shiny::icon("cog"),
      style = "position: fixed; bottom: 15px; right: 15px; color: #FFFFFF; z-index: 9999; background-color: #0000FF; padding: 15px;"
    )
  )

  if (length(sign_in_page_args) > 0) {
    secure_ui_args$sign_in_page_ui <- do.call(sign_in_ui_default, sign_in_page_args)
  }

  ui_out <- do.call(secure_ui, secure_ui_args)

  server <- secure_server(function(input, output, session) {

    observeEvent(input$sign_out, {

      tryCatch({
        sign_out_from_shiny(session)
        session$reload()
      }, error = function(err) {
        print(err)
      })

    })
  })


  shiny::shinyApp(ui_out, server)
}

# copied internal function from rsconnect package
# https://github.com/rstudio/rsconnect/blob/250aa5c0c5071c1ae3f7ecc407164da5801bc17e/R/bundle.R#L496
yamlFromRmd <- function (filename) {
  lines <- readLines(filename, warn = FALSE, encoding = "UTF-8")
  delim <- grep("^(---|\\.\\.\\.)\\s*$", lines)
  if (length(delim) >= 2) {
    if (delim[[1]] == 1 || all(grepl("^\\s*$", lines[1:delim[[1]]]))) {
      if (grepl("^---\\s*$", lines[delim[[1]]])) {
        if (diff(delim[1:2]) > 1) {
          yamlData <- paste(lines[(delim[[1]] + 1):(delim[[2]] -
                                                      1)], collapse = "\n")
          return(yaml::yaml.load(yamlData))
        }
      }
    }
  }
  return(NULL)
}