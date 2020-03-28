#' sign_in_ui_default
#'
#' @param firebase_config Firebase configuration
#' @param color hex color for the background and button
#' @param company_name your company name
#' @param logo_top html for logo to go above the sign in panel.
#' @param logo_bottom html for the logo below the sign in panel.
#'
#' @export
#'
#' @importFrom shiny fluidPage fluidRow column
#' @importFrom htmltools tags HTML
#' @importFrom stringr str_interp
#'
#' @return the UI for the sign in page
#'
sign_in_ui_default <- function(
  firebase_config,
  color = "#2491EB",
  company_name = "Tychobra LLC",
  logo_top = tags$img(
    src="polish/images/polished_logo_transparent_white.png",
    width = "100px",
    style = "padding-top: 15px; padding-bottom: 15px;"
  ),
  logo_bottom = tags$img(
    src = "polish/images/polished_logo_transparent_text_2.png",
    alt = "Polished Logo",
    style = "width: 200px; margin-bottom: 15px; padding-top: 15px;"
  )
) {

  shiny::fluidPage(
    style = "height: 100vh;",
    tags$head(
      tags$title("Polished"),
      tags$link(rel = "shortcut icon", href = "images/polished_logo_transparent.png"),
      tags$meta(
        name = "viewport",
        content = "
        width=device-width,
        initial-scale=1,
        maximum-scale=1,
        minimum-scale=1,
        user-scalable=no,
        viewport-fit=cover"
      ),
      tags$style(
        stringr::str_interp("
        .auth_panel {
          width: 300px;
          max-width: 100%;
          padding: 10px 25px;
          background: #fff;
          color: #080021;
          z-index: 20000;
        }

        .btn-primary {
          background-color: ${color} !important;
          border: none;
        }

        .footer {
          color: #FFF;
          text-align: center;
          z-index: 1;
          margin-top: -40px;
        }

        body {
          background-color: ${color};
        }

        /*label {
          text-align: left !important;
        }*/
      ")
      )
    ),
    shiny::fluidRow(
      style = "padding-bottom: 50px; min-height: 100%;",
      shiny::column(
        width = 12,
        align = "center",
        tags$div(
          style = "width: 300px; max-width: 100%;",
          logo_top
        ),
        sign_in_module_ui(
          "sign_in",
          firebase_config
        ),
        tags$div(
          style = "width: 300px; max-width: 100%; background-color: #FFF",
          tags$hr(style="padding: 0; margin: 0;"),
          logo_bottom
        )
      )
    ),
    shiny::fluidRow(
      shiny::column(
        12,
        class = "footer",
        tags$p(
          style = "color: #FFF; text-align: center;",
          htmltools::HTML("&copy;"),
          paste0(
            substr(Sys.Date(), 1, 4),
            " - ",
            company_name
        )
      )
    )
  ))
}
