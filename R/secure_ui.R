#' Secure your Shiny UI
#'
#' This function is used to secure your Shiny app's UI.  Make sure to pass
#' your Shiny app's UI as the first argument to \code{secure_ui()} at
#' the bottom of your Shiny app's \code{ui.R} file.
#'
#' @param ui UI of the application.
#' @param sign_in_page_ui Either \code{NULL}, the default (See \code{\link{sign_in_ui_default}}), or the HTML, CSS, and JavaScript
#' to use for the UI of the Sign In page.
#' @param custom_admin_ui Either \code{NULL}, the default, or a list of 2 Shiny module UI functions
#' to add additional \code{shinydashboard} tabs to the \code{polished} Admin Panel. The list must be in the form:
#' \preformatted{
#' list(
#'   "menu_items" = <your_custom_admin_menu_ui("custom_admin")>,
#'   "tab_items" = <your_custom_admin_tabs_ui("custom_admin")>
#' )
#' }
#' @param custom_admin_button_ui Either \code{admin_button_ui()}, the default, or your custom
#' UI to take Admins from the custom Shiny app to the \code{polished} Admin Panel.
#' @param admin_ui_options list of HTML elements to customize branding of the \code{polished} Admin Panel.  Valid
#' list element names are \code{title}, \code{sidebar_branding}, and \code{browser_tab_icon}.  See
#' \code{\link{default_admin_ui_options}}, the default.
#' @param account_module_ui the UI portion for the user's account module.
#' @param splash_module_ui the UI portion for the splash page module.
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
  custom_admin_button_ui = admin_button_ui(),
  admin_ui_options = default_admin_ui_options(),
  account_module_ui = NULL,
  splash_module_ui = NULL
) {


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

    # if a token exists attempt to sign in the user using the token.  This is used to automatically
    # sign a user in via an email link without requiring the user to enter their email
    # and password.
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

    request$polished_user <- user

    if (is.function(ui)) {
      ui <- ui(request)
    } else {
      ui <- (function(request) ui)()
    }
    ui <- force(ui)


    # UI to optionally add Sentry.io error monitoring
    sentry_ui_out <- function(x) NULL
    sentry_dsn <- getOption("polished")$sentry_dsn
    if (!is.null(sentry_dsn)) {

      sentry_ui_out <- sentry_ui(
        sentry_dsn = sentry_dsn,
        app_uid = paste0(getOption("polished")$app_name, "@", getOption("polished")$app_uid),
        user = user,
        r_env = if (Sys.getenv("R_CONFIG_ACTIVE") == "") "default" else Sys.getenv("R_CONFIG_ACTIVE")
      )

    }

    page_out <- NULL

    if (is.null(user)) {

      if (!is.null(splash_module_ui) && is.null(page_query)) {

        page_out <- tagList(
          splash_module_ui,
          tags$script(src = "polish/js/router.js?version=3"),
          sentry_ui_out("splash")
        )

      } else if (identical(page_query, "sign_in")) {
        # go to the sign in page
        if (is.null(sign_in_page_ui)) {

          # go to default sign in page
          page_out <- tagList(
            sign_in_ui_default(),
            tags$script(src = "polish/js/router.js?version=3"),
            sentry_ui_out("sign_in_default")
          )

        } else {

          # go to custom sign in page
          page_out <- tagList(
            sign_in_page_ui,
            tags$script(src = "polish/js/router.js?version=3"),
            sentry_ui_out("sign_in_custom")
          )
        }

      } else {


        if (isFALSE(.global_sessions$is_auth_required)) {

          # auth is not required, so allow the user to go directly to the custom shiny app
          # go to Shiny app without admin button.  User is not an admin
          page_out <- tagList(
            ui,
            tags$script(src = "polish/js/router.js?version=3"),
            tags$script(src = "polish/js/polished_session.js?version=2"),
            tags$script(paste0("polished_session('", user$hashed_cookie, "')")),
            sentry_ui_out("shiny_app")
          )
        } else {
          # send a random uuid as the polished_session.  This will trigger a session
          # reload and a redirect to the sign in page
          page_out <- tagList(
            tags$script(src = "polish/js/router.js?version=3"),
            tags$script(src = "polish/js/polished_session.js?version=2"),
            tags$script(paste0("polished_session('", uuid::UUIDgenerate(), "')"))
          )
        }

      }


    } else {
      # user is not NULL

      if (identical(page_query, "sign_in")) {
        # send signed in session to polished_session.  This will trigger
        # a redirect to the app
        page_out <- tagList(
          tags$script(src = "polish/js/router.js?version=3"),
          tags$script(src = "polish/js/polished_session.js?version=2"),
          tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
        )
      } else if (isTRUE(user$email_verified) ||
          isFALSE(.global_sessions$is_email_verification_required)) {


        if (identical(page_query, "account")) {

          # server the payments module UI
          if (is.null(account_module_ui)) {
            stop("`account_module_ui` cannot be NULL", call. = FALSE)
          } else {
            page_out <- tagList(
              account_module_ui,
              tags$script(src = "polish/js/router.js?version=3"),
              tags$script(src = "polish/js/polished_session.js?version=2"),
              tags$script(paste0("polished_session('", user$hashed_cookie, "')")),
              sentry_ui_out("account")
            )
          }

        } else if (isTRUE(user$is_admin)) {

          if (identical(page_query, "admin_panel")) {

            # go to Admin Panel
            page_out <- tagList(
              admin_module_ui("admin", custom_admin_ui, options = admin_ui_options),
              tags$script(src = "polish/js/router.js?version=3"),
              tags$script(src = "polish/js/polished_session.js?version=2"),
              tags$script(paste0("polished_session('", user$hashed_cookie, "')")),
              sentry_ui_out("admin_panel")
            )
          } else if (is.null(page_query)) {

            # go to Shiny app with admin button.  User is an admin.
            page_out <- tagList(
              ui,
              custom_admin_button_ui,
              tags$script(src = "polish/js/router.js?version=3"),
              tags$script(src = "polish/js/polished_session.js?version=2"),
              tags$script(paste0("polished_session('", user$hashed_cookie, "')")),
              sentry_ui_out("shiny_app")
            )
          }


        } else {

          # go to Shiny app without admin button.  User is not an admin
          page_out <- tagList(
            ui,
            tags$script(src = "polish/js/router.js?version=3"),
            tags$script(src = "polish/js/polished_session.js?version=2"),
            tags$script(paste0("polished_session('", user$hashed_cookie, "')")),
            sentry_ui_out("shiny_app")
          )

        } # end is_admin check
      } else {
        # email is not verified.
        # go to email verification page

        page_out <- tagList(
          verify_email_module_ui(
            "verify"
          ),
          tags$script(src = "polish/js/router.js?version=3"),
          tags$script(src = "polish/js/polished_session.js?version=2"),
          tags$script(paste0("polished_session('", user$hashed_cookie, "')")),
          sentry_ui_out("email_verification")
        )
      }


    }

    page_out
  } # end request handler function
}
