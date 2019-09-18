#' Secure the Shiny Application UI
#'
#' @param ui UI of the application.
#' @param firebase_config A list containing your Firebase project configuration.  This will
#' be passed to \code{\link{firebase_init()}}.
#' @param app_name The name of the app.
#' @param sign_in_page_ui Either `NULL`, the default, or the HTML, CSS, and JavaScript
#' to use for the UI of the Sign In page.
#' @param custom_admin_ui Either `NULL`, the default, or a list of 2 elements containing custom
#' ui to add addtional `shinydashboard` tabs to the Polished admin panel.
#' @param custom_admin_button_ui Either `admin_button_ui("polished")`, the default, ot your custom
#' ui to take admins from the custom Shiny app to the Admin panel.
#'
#' @return Secured Shiny app ui
#'
#' @export
#'
#' @importFrom shiny fluidPage fluidRow column actionButton
#' @importFrom htmltools tagList h1
#'
#'
secure_ui <- function(
  ui,
  firebase_config,
  app_name,
  sign_in_page_ui = NULL,
  custom_admin_ui = NULL,
  custom_admin_button_ui = admin_button_ui("polished")
) {

  ui <- force(ui)
  custom_admin_button_ui <- force(custom_admin_button_ui)

  function(request) {
    query <- parseQueryString(request$QUERY_STRING)

    cookie_string <- request$HTTP_COOKIE

    uid <- NULL
    if (!is.null(cookie_string)) {
      uid <- get_cookie(cookie_string, "polish__uid")
      polished_session <- get_cookie(cookie_string, "polish__session")
    }

    user <- NULL
    if (!is.null(uid) && !is.null(polished_session) && length(uid) > 0 && length(polished_session)) {
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
              admin_module_ui("admin", firebase_config, custom_admin_ui)
            )
          } else {

            page_out <- tagList(
              tags$head(
                tags$script(paste0("var app_name = '", app_name, "'")),
                tags$link(rel = "stylesheet", href = "polish/css/all.css")
              ),
              ui,
              custom_admin_button_ui,
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
