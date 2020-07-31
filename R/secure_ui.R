#' Secure your 'shiny' UI
#'
#' This function is used to secure your 'shiny' app's UI.  Make sure to pass
#' your 'shiny' app's UI as the first argument to \code{secure_ui()} at
#' the bottom of your 'shiny' app's "ui.R" file.
#'
#' @param ui UI of the application.
#' @param sign_in_page_ui Either \code{NULL}, the default, or the HTML, CSS, and JavaScript
#' to use for the UI of the Sign In page.
#' @param custom_admin_ui Either \code{NULL}, the default, or a list of 2 elements containing custom
#' UI to add additional 'shinydashboard' tabs to the Polished admin panel.
#' @param custom_admin_button_ui Either \code{admin_button_ui("polished")}, the default, or your custom
#' UI to take admins from the custom Shiny app to the Admin panel.
#' @param admin_ui_options list of html elements to customize branding of the "Admin Panel".  Valid
#' list element names are "title", "sidebar_branding", and "browser_tab_icon".  See
#' \code{\link{default_admin_ui_options}} for an example.
#'
#' @return Secured Shiny app UI
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
  sign_in_page_ui = NULL,
  custom_admin_ui = NULL,
  custom_admin_button_ui = admin_button_ui("polished"),
  admin_ui_options = default_admin_ui_options()
) {

  ui <- force(ui)
  custom_admin_button_ui <- force(custom_admin_button_ui)

  function(request) {

    if (isTRUE(.global_sessions$get_admin_mode())) {

      # go to Admin Panel
      return(tagList(
        admin_module_ui(
          "admin",
          custom_admin_ui,
          options = admin_ui_options,
          include_go_to_shiny_app_button = FALSE
        ),
        tags$script(src = "polish/js/polished_session.js?version=2"),
        tags$script(paste0("polished_session('", uuid::UUIDgenerate(), "')"))
      ))

    }

    query <- shiny::parseQueryString(request$QUERY_STRING)
    page_query <- query$page
    cookie_string <- request$HTTP_COOKIE

    hashed_cookie <- NULL
    if (!is.null(cookie_string)) {
      polished_cookie <- get_cookie(cookie_string, "polished")
      hashed_cookie <- digest::digest(polished_cookie)
    }

    if (!is.null(query$token)) {
      query_cookie <- query$token
      return(
        tagList(
          tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
          tags$script(paste0("
            Cookies.set(
              'polished',
              '", query_cookie, "',
              { expires: 365 } // set cookie to expire in 1 year
            )

            window.location.href = window.location.origin + window.location.pathname;

          "))
        )
      )
    }


    user <- NULL
    if (!is.null(hashed_cookie) && length(hashed_cookie) > 0) {
      tryCatch({
        user <- .global_sessions$find(hashed_cookie, paste0("ui-", page_query))
      }, error = function(error) {
        print("sign_in_ui_1")
        print(error)
      })
    }


    page_out <- NULL

    if (identical(page_query, "set_password")) {

      email <- query$email
      passcode <- query$verify_code

      page_out <- set_password_module_ui("set_pass")

    } else if (is.null(user)) {



      if (identical(page_query, "sign_in")) {
        # go to the sign in page
        if (is.null(sign_in_page_ui)) {

          # go to default sign in page
          if (isTRUE(.global_sessions$is_invite_required)) {
            page_out <- tagList(
              sign_in_ui_default()
            )
          } else {
            page_out <- tagList(
              sign_in_ui_default(
                sign_in_module = sign_in_no_invite_module_ui("sign_in")
              )
            )
          }

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
          tags$script(src = "polish/js/polished_session.js?version=2"),
          tags$script(paste0("polished_session('", uuid::UUIDgenerate(), "')"))
        )
      }


    } else {

      if (isTRUE(user$email_verified)) {

        if (isTRUE(user$is_admin)) {


          if (identical(page_query, "admin_panel")) {

            # go to Admin Panel
            page_out <- tagList(
              admin_module_ui("admin", custom_admin_ui, options = admin_ui_options),
              tags$script(src = "polish/js/polished_session.js?version=2"),
              tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
            )
          } else {

            # go to Shiny app with admin button.  User is an admin.
            page_out <- tagList(
              ui,
              custom_admin_button_ui,
              tags$script(src = "polish/js/polished_session.js?version=2"),
              tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
            )
          }


        } else {

          # go to Shiny app without admin button.  User is not an admin
          page_out <- tagList(
            ui,
            tags$script(src = "polish/js/polished_session.js?version=2"),
            tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
          )

        } # end is_admin check
      } else {
        # email is not verified.
        # go to email verification page

        page_out <- tagList(
          verify_email_module_ui(
            "verify"
          ),
          tags$script(src = "polish/js/polished_session.js?version=2"),
          tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
        )
      }


    }
    page_out
  } # end request handler function
}
