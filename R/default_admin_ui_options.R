#' Default Options for the Admin UI
#'
#' This function specifies the default logos that are displayed in the "Admin Panel".
#'
#' @return a list of html for branding the Admin UI
#'
#'
default_admin_ui_options <- function() {
  list(


    title = tagList(
      tags$a(
        href = "https://polished.tech/",
        tags$img(
          src="polish/images/polished_logo_transparent_text_2.png",
          style = "height: 37.5px; width: 180px; padding: 0",
          alt = "Polished Logo"
        )
      ),
      htmltools::tags$head(htmltools::tags$title("Polished"))
    ),


    sidebar_branding = tags$a(
      href = "https://www.tychobra.com/",
      tags$img(
        style = "position: fixed; bottom: 0; left: 0; width: 230px;",
        src = "polish/images/tychobra_logo_blue_co_name.png"
      )
    ),

    browser_tab_icon = tags$link(
      rel = "shortcut icon",
      href = "polish/images/polished_icon.png"
    )
  )
}
