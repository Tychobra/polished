#' Secure a Shiny application and manage authentication
#'
#' @param ui UI of the application.
#' @param firebase_config list of firebase configuration
#' @param app_name the name of the app
#'
#' @return shiny app ui
#'
#' @export
#'
#' @importFrom shiny fluidPage fluidRow column actionButton
#' @importFrom htmltools tagList h1
#'
#'
#' @examples
#' if (interactive()) {
#'
#'
#'   library(shiny)
#'   library(tychobraauth)
#'
#'
#'   server <- function(input, output, session) {
#'
#'     # call the server part
#'     # check_credentials returns a function to authenticate users
#'
#'
#'     output$auth_output <- renderPrint({
#'       "HI"
#'       #reactiveValuesToList(res_auth)
#'     })
#'
#'   }
#'
#'   shinyApp(ui, server)
#'
#' }
secure_ui <- function(ui, firebase_config, app_name) {
  ui <- force(ui)

  function(request) {
    query <- parseQueryString(request$QUERY_STRING)
    token <- query$token

    user <- NULL
    out <- NULL

    if (is.null(token)) {


      # go to the sign in view
      out <- fluidPage(
        tags$head(
          tags$script(paste0("var app_name = '", app_name, "'"))
        ),
        fluidRow(
          sign_in_ui(firebase_config)
        )
      )

    } else {

      user <- .global_users$find_user_by_token(token)

      if (is.null(user)) {
        out <- fluidPage(
          tags$head(
            tags$script(paste0("var app_name = '", app_name, "'"))
          ),
          fluidRow(
            column(
              12,
              style = "margin-top: 150px",
              class = "text-center",
              h1("Error: user not found")
            )
          )
        )

      } else if (isTRUE(user$get_is_authed())) {

        is_email_verified <- user$get_email_verified()
        is_admin <- user$get_is_admin()


        if (isTRUE(is_email_verified)) {

          if (isTRUE(is_admin)) {

            admin_panel_query <- query$admin_panel

            if (is.null(admin_panel_query)) {

              # go to Admin Panel
              out <- tagList(
                tags$head(
                  tags$script(paste0("var app_name = '", app_name, "'"))
                ),
                admin_module_ui("admin", firebase_config),
                tags$script(paste0("
              $(document).on('shiny:sessioninitialized', function() {
                Shiny.setInputValue('polish__token', '", token, "')
              })
            "))
              )
            } else {
              out <- tagList(
                tags$head(
                  tags$script(paste0("var app_name = '", app_name, "'"))
                ),
                ui,
                actionButton(
                  "polish__go_to_admin_panel",
                  "Admin Panel",
                  icon = icon("cog"),
                  class = "btn-primary btn-lg",
                  style = "position: fixed; bottom: 15px; right: 15px; color: #FFFFFF;"
                ),
                firebase_dependencies(),
                firebase_init(firebase_config),
                tags$script(src = "polish/all.js"),
                tags$script(paste0("
              $(document).on('shiny:sessioninitialized', function() {
                Shiny.setInputValue('polish__token', '", token, "')
              })
            "))
              )
            }


          } else {

            # go to Shiny app
            out <- tagList(
              tags$head(
                tags$script(paste0("var app_name = '", app_name, "'"))
              ),
              ui,
              firebase_dependencies(),
              firebase_init(firebase_config),
              tags$script(src = "polish/all.js"),
              tags$script(paste0("
              $(document).on('shiny:sessioninitialized', function() {
                Shiny.setInputValue('polish__token', '", token, "')
              })
            "))
            )

          } # end is_admin check

        } else {

          # show email verification view
          out <- verify_email_ui("verify", firebase_config, token)

        } # end is_email_verified block

      } else {

        # global_user user exists, but is not signed in, so go to the sign in view
        out <- fluidPage(
          tags$head(
            tags$script(paste0("var app_name = '", app_name, "'"))
          ),
          fluidRow(
            sign_in_ui(firebase_config)
          )
        )

      } # end is_authed block

    } # end is.null(token) block

    out
  } # end request handler function
}
