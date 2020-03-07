#' Secure the Shiny Application UI
#'
#' @param ui UI of the application.
#' @param firebase_config Firebase configuration.
#' @param sign_in_page_ui Either `NULL`, the default, or the HTML, CSS, and JavaScript
#' to use for the UI of the Sign In page.
#' @param custom_admin_ui Either `NULL`, the default, or a list of 2 elements containing custom
#' ui to add addtional `shinydashboard` tabs to the Polished admin panel.
#' @param custom_admin_button_ui Either `admin_button_ui("polished")`, the default, ot your custom
#' ui to take admins from the custom Shiny app to the Admin panel.
#' @param admin_ui_options list of custom UI options.  Passed as argument to `admin_module_ui()`.
#'
#' @return Secured Shiny app ui
#'
#' @export
#'
#' @importFrom shiny fluidPage fluidRow column actionButton parseQueryString
#' @importFrom htmltools tagList h1 tags
#' @importFrom digest digest
#' @importFrom uuid UUIDgenerate
#'
#'
secure_ui <- function(
  ui,
  firebase_config,
  sign_in_page_ui = NULL,
  custom_admin_ui = NULL,
  custom_admin_button_ui = admin_button_ui("polished"),
  admin_ui_options = default_admin_ui_options()
) {

  ui <- force(ui)
  custom_admin_button_ui <- force(custom_admin_button_ui)

  function(request) {
    query <- shiny::parseQueryString(request$QUERY_STRING)

    cookie_string <- request$HTTP_COOKIE

    polished_token <- NULL
    if (!is.null(cookie_string)) {
      polished_cookie <- get_cookie(cookie_string, "polished__token")
      polished_token <- digest::digest(polished_cookie)
    }


    user <- NULL
    if (!is.null(polished_token) && length(polished_token) > 0) {
      tryCatch({
        user <- .global_sessions$find(polished_token)
      }, error = function(error) {
        print("sign_in_ui_1")
        print(error)
      })
    }


    page_out <- NULL

    if (is.null(user)) {

      page_query <- query$page

      if (identical(page_query, "sign_in")) {
        # go to the sign in page
        if (is.null(sign_in_page_ui)) {

          # go to default sign in page
          page_out <- tagList(
            sign_in_ui_default(firebase_config)
          )

        } else {

          # go to custom sign in page
          page_out <- tagList(
            sign_in_page_ui
          )
        }
      } else {

        # send a random uuid as the polished_session.  This will trigger a session
        # reload and a redirect to the sign in page
        page_out <- tagList(
          tags$script(src = "polish/js/polished_session.js"),
          tags$script(paste0("polished_session('", uuid::UUIDgenerate(), "')"))
        )
      }


    } else {

      if (isTRUE(user$email_verified)) {

        if (isTRUE(user$is_admin)) {

          page_query <- query$page

          if (identical(page_query, "admin_panel")) {

            # go to Admin Panel
            page_out <- tagList(
              admin_module_ui("admin", firebase_config, custom_admin_ui, options = admin_ui_options),
              tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
              tags$script(src = "polish/js/polished_session.js"),
              tags$script(paste0("polished_session('", user$token, "')"))
            )
          } else {

            # go to Shiny app with admin button.  User is an admin.
            page_out <- tagList(
              ui,
              custom_admin_button_ui,
              tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
              tags$script(src = "polish/js/polished_session.js"),
              tags$script(paste0("polished_session('", user$token, "')"))
            )
          }


        } else {

          # go to Shiny app without admin button.  User is not an admin
          page_out <- tagList(
            ui,
            tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
            tags$script(src = "polish/js/polished_session.js"),
            tags$script(paste0("polished_session('", user$token, "')"))
          )

        } # end is_admin check
      } else {
        # email is not verified.
        # go to email verification page

        page_out <- tagList(
          verify_email_module_ui(
            "verify",
            firebase_config
          ),
          tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
          tags$script(src = "polish/js/polished_session.js"),
          tags$script(paste0("polished_session('", user$token, "')"))
        )
      }


    }
    page_out
  } # end request handler function
}
