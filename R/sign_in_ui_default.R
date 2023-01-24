#' Default UI styles for the Sign In & Registration pages
#'
#' Default styling for the sign in & registration pages.  Update the \code{sign_in_ui_default()}
#' arguments with your brand and colors to quickly style the sign in & registration
#' pages to match your brand.
#'
#' @param sign_in_module UI module for the Sign In & Registration pages.
#' @param color hex color for the background and button.
#' @param company_name your company name.
#' @param logo_top HTML for logo to go above the sign in panel.
#' @param logo_bottom HTML for the logo below the sign in panel.
#' @param icon_href the URL/path to the browser tab icon.
#' @param background_image the URL/path to a full width background image.  If set to \code{NULL},
#' the default, the \code{color} argument will be used for the background instead of this
#' image.
#' @param terms_and_privacy_footer links to place in the footer, directly above the copyright
#' notice.
#' @param align The horizontal alignment of the Sign In box. Defaults to \code{"center"}. Valid
#' values are \code{"left"}, \code{"center"}, or \code{"right"}
#' @param button_color the color of the "Continue", "Sign In", and "Register" buttons.  If kept
#' as \code{NULL}, the default, then the button color will be the same color as the color passed to
#' the \code{color} argument.
#' @param footer_color the text color for the copyright text in the footer.
#'
#' @export
#'
#' @importFrom shiny fluidPage fluidRow column
#' @importFrom htmltools tags HTML
#' @importFrom stringr str_interp
#'
#' @return the html and css to create the default sign in UI.
#'
#' @return the UI for the Sign In & Registration pages
#'
sign_in_ui_default <- function(
  sign_in_module = sign_in_module_ui("sign_in"),
  color = "#5ec7dd",
  company_name = "Your Brand Here",
  logo_top = tags$div(
    style = "width: 300px; max-width: 100%; color: #FFF;",
    class = "text-center",
    h1("Your", style = "margin-bottom: 0; margin-top: 30px;"),
    h1("Brand", style = "margin-bottom: 0; margin-top: 10px;"),
    h1("Here", style = "margin-bottom: 15px; margin-top: 10px;")
  ),
  logo_bottom = NULL,
  icon_href = "polish/images/polished_icon.png",
  background_image = NULL,
  terms_and_privacy_footer = NULL,
  align = "center",
  button_color = NULL,
  footer_color = "#FFF"
) {

  if (is.null(background_image)) {
    background_image_css <-  stringr::str_interp("")
  } else {
    background_image_css <- stringr::str_interp("
      background-image: url(${background_image});
      background-repeat: no-repeat;
      background-position: center center;
      background-size: cover;
    ")
  }

  if (length(align) != 1 && !(align %in% c("left", "center", "right"))) {
    stop('`align` must be either "lect", "center", or "right"', call. = FALSE)
  }

  if (is.null(terms_and_privacy_footer)) {
    footer_margin <- -40
  } else {
    footer_margin <- -68
  }


  if (align == "center") {
    left_col <- list()
    main_width <- 12
    right_col <- list()
  } else if (align == "left") {
    left_col <- list()
    main_width <- 6
    right_col <- column(6)
  } else {
    left_col <- column(6)
    main_width <- 6
    right_col <- list()
  }

  if (is.null(button_color)) {
    button_color <- color
  }


  shiny::fluidPage(
    style = "height: 100vh;",
    tags$head(
      tags$link(rel = "shortcut icon", href = icon_href),
      tags$title(company_name),
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
          width: 100%;
          max-width: 300px;
          padding: 10px 25px;
          background-color: #fff;
          color: #080021;
          margin: 0 auto;
          box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
        }

        .auth_panel_2 {
          width: 100%;
          max-width: 600px;
          padding: 10px 25px;
          background-color: #fff;
          color: #080021;
          margin: 0 auto;
          box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
        }

        .btn-primary {
          background-color: ${button_color} !important;
          border: none;
          width: 100%;
          color: #FFF;
        }

        .footer {
          color: ${footer_color};
          text-align: center;
          z-index: 1;
          margin-top: ${footer_margin}px;
        }

        body {
          background-color: ${color} !important;
          ${background_image_css}
        }

      ")
      )
    ),
    shiny::fluidRow(
      style = "padding-bottom: 50px; min-height: 100%;",
      left_col,
      shiny::column(
        width = main_width,
        align = "center",
        logo_top,
        tags$div(
          sign_in_module,
          logo_bottom
        )
      ),
      right_col
    ),
    shiny::fluidRow(
      shiny::column(
        12,
        class = "footer",
        terms_and_privacy_footer,
        tags$p(
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
