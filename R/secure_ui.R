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
#'
#' @return Secured Shiny app ui
#'
#' @export
#'
#' @importFrom shiny fluidPage fluidRow column actionButton
#' @importFrom htmltools tagList h1 tags
#'
#'
secure_ui <- function(
  ui,
  firebase_config,
  sign_in_page_ui = NULL,
  custom_admin_ui = NULL,
  custom_admin_button_ui = admin_button_ui("polished")
) {

  ui <- force(ui)
  custom_admin_button_ui <- force(custom_admin_button_ui)

  function(request) {
    query <- parseQueryString(request$QUERY_STRING)

    cookie_string <- request$HTTP_COOKIE
    #print(list(
    #  request = as.list(request)
    #))
    polished_token <- NULL
    if (!is.null(cookie_string)) {
      polished_token <- get_cookie(cookie_string, "polished__token")
    }

    # Check if jwt is in the query string.  If it is, then attempt to sign in the user. Pass the
    # cookie with the sign in.  If the sign in succeeds we will add this cookie as the session token,
    # so we can go straight to the authed page with out an additional page reload.
    #if (!is.null(query$jwt)) {
    #  .global_sessions$sign_in(query$jwt, polished_token)
    #}

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

      if (isTRUE(user$email_verified)) {

        if (isTRUE(user$is_admin)) {

          admin_panel_query <- query$admin_panel

          if (identical(admin_panel_query, "true")) {

            # go to Admin Panel
            page_out <- tagList(
              admin_module_ui("admin", firebase_config, custom_admin_ui),
              tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js")
            )
          } else {

            page_out <- tagList(
              ui,
              custom_admin_button_ui,
              tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js")
            )
          }


        } else {

          # go to Shiny app without admin button.  User is not an admin
          page_out <- tagList(
            ui,
            tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js")
          )

        } # end is_admin check
      } else {
        # email is not verified.
        # go to email verification page

        page_out <- tagList(
          verify_email_ui(
            "verify",
            firebase_config
          ),
          tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js")
        )
      }


    }
    page_out
  } # end request handler function
}
