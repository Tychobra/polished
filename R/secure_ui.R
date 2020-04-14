#' Secure the Shiny Application UI
#'
#' @param ui UI of the application.
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

    cookie_string <- request$HTTP_COOKIE

    hashed_cookie <- NULL
    if (!is.null(cookie_string)) {
      polished_cookie <- get_cookie(cookie_string, "polished")
      hashed_cookie <- digest::digest(polished_cookie)
    }


    user <- NULL
    if (!is.null(hashed_cookie) && length(hashed_cookie) > 0) {
      tryCatch({
        user <- .global_sessions$find(hashed_cookie)
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
            sign_in_ui_default()
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
          tags$script(src = "polish/js/polished_session.js?version=2"),
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
