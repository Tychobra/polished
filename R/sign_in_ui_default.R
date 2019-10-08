#' sign_in_ui_default
#'
#' @param firebase_config Firebase configuration
#'
#' @export
#'
#' @return the UI for the sign in page
#'
sign_in_ui_default <- function(firebase_config) {
  fluidPage(
    tags$head(
      tags$style("
        .auth_panel {
          width: 350px;
          max-width: 100%;
          margin: 0 auto;
          margin-top: 75px;
          border: 2px solid #eee;
          border-radius: 25px;
          padding: 30px;
          background: #f9f9f9;
        }
      ")
    ),
    fluidRow(
      sign_in_module_ui(
        "sign_in",
        firebase_config
      )
    )
  )
}
