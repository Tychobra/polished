#' Secure a Shiny application and manage authentication
#'
#' @param ui UI of the application.
#' @param firebase_config list of firebase configuration
#' @param app_name the name of the app
#' @param sign_in_page_ui either NULL, the default, or the HTML, CSS, and JavaScript
#' to use for the UI of the Sign In page
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
secure_ui <- function(ui, firebase_config, app_name, sign_in_page_ui = NULL) {
  ui <- force(ui)

  function(request) {
    query <- parseQueryString(request$QUERY_STRING)

    cookie_string <- request$HTTP_COOKIE

    uid <- NULL
    if (!is.null(cookie_string)) {
      uid <- get_cookie(cookie_string, "polish__uid")
      polished_session <- get_cookie(cookie_string, "polish__session")
    }

    user <- NULL
    if (!is.null(uid)) {
      tryCatch({
        user <- .global_users$find_user_by_uid(uid, polished_session)
      }, error = function(error) {
        print("sign_in_ui_1")
        print(error)
      })
    }


    page_out <- NULL
    if (is.null(user)) {

      # go to the sign in page
      if (is.null(sign_in_page_ui)) {

        # go to default sign in page
        page_out <- tagList(
          tags$head(
            tags$script(paste0("var app_name = '", app_name, "'")),
            tags$link(rel = "stylesheet", href = "polish/css/all.css")
          ),
          sign_in_ui_default(firebase_config)
        )
      } else {

        # go to custom sign in page
        page_out <- tagList(
          tags$head(
            tags$script(paste0("var app_name = '", app_name, "'")),
            tags$link(rel = "stylesheet", href = "polish/css/all.css")
          ),
          sign_in_page_ui
        )
      }

    } else {


      is_email_verified <- user$get_email_verified()
      is_admin <- user$get_is_admin()


      if (isTRUE(is_email_verified)) {

        if (isTRUE(is_admin)) {

          admin_panel_query <- query$admin_panel

          if (identical(admin_panel_query, "true")) {

            # go to Admin Panel
            page_out <- tagList(
              tags$head(
                tags$script(paste0("var app_name = '", app_name, "'")),
                tags$link(rel = "stylesheet", href = "polish/css/all.css")
              ),
              admin_module_ui("admin", firebase_config)
            )
          } else {

            page_out <- tagList(
              tags$head(
                tags$script(paste0("var app_name = '", app_name, "'")),
                tags$link(rel = "stylesheet", href = "polish/css/all.css")
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
              tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
              tags$script(src = "polish/js/all.js"),
          tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
              tags$script(src = "polish/js/auth-state.js")
            )
          }


         } else {

            # go to Shiny app
            page_out <- tagList(
              tags$head(
                tags$script(paste0("var app_name = '", app_name, "'")),
                tags$link(rel = "stylesheet", href = "polish/css/all.css")
              ),
              ui,
              firebase_dependencies(),
              firebase_init(firebase_config),
              tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
              tags$script(src = "polish/js/all.js"),
              tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
              tags$script(src = "polish/js/auth-state.js")
            )

          } # end is_admin check

        } else {

          # show email verification view
          page_out <- verify_email_ui("verify", firebase_config)

        } # end is_email_verified block

      }
    page_out
  } # end request handler function
}
