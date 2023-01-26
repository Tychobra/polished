




#' Secure your Shiny UI
#'
#' This function is used to secure your Shiny app's UI.  Make sure to pass
#' your Shiny app's UI as the first argument to \code{secure_ui()} at
#' the bottom of your Shiny app's \code{ui.R} file.
#'
#' @param ui UI of the application.
#' @param sign_in_page_ui Either \code{NULL}, the default (See \code{\link{sign_in_ui_default}}), or the Shiny
#' UI for a custom Sign In page.
#' @param custom_admin_ui Either \code{NULL}, the default, or the Shiny UI for a custom
#' Admin Panel.
#' @param custom_admin_button_ui Either \code{admin_button_ui()}, the default, or your custom
#' UI to take Admins from the custom Shiny app to the \code{polished} Admin Panel.  Set to
#' \code{NULL} to exclude the button.
#' @param admin_ui_options list of HTML elements to customize branding of the \code{polished} Admin Panel.  This
#' argument is only applicable if the \code{custom_admin_ui} is set to \code{NULL}.  If a \code{custom_admin_ui}
#' is provided, then these options will be ignored. Valid
#' list element names are \code{title}, \code{sidebar_branding}, and \code{browser_tab_icon}.  See
#' \code{\link{default_admin_ui_options}}, the default.
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
  admin_ui_options = default_admin_ui_options()
) {


  custom_admin_button_ui <- force(custom_admin_button_ui)



  function(request) {

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
    polished_user <- NULL
    force_sign_out <- FALSE
    if (!is.null(hashed_cookie) && length(hashed_cookie) > 0) {

      tryCatch({
        user_res <- get_sessions(
          app_uid = .polished$app_uid,
          hashed_cookie = hashed_cookie
        )

        user <- user_res$content

        if (!is.null(user)) {

          if (is.na(user$signed_in_as)) {
            polished_user <- user[
              c("session_uid", "user_uid", "email", "is_admin", "hashed_cookie", "email_verified", "roles", "two_fa_verified")
            ]

          } else {
            polished_user <- get_signed_in_as_user(
              user_uid = user$signed_in_as
            )
            polished_user$session_uid <- user$session_uid
            polished_user$hashed_cookie <- user$hashed_cookie
            polished_user$email_verified <- user$email_verified
            polished_user$two_fa_verified <- user$two_fa_verified
          }

        }



      }, error = function(err) {

        if (isTRUE(.polished$is_auth_required) && identical(err$message, "user not invited") && !identical(page_query, "sign_in")) {
          force_sign_out <<- TRUE
        }

        warning(conditionMessage(err))

        invisible(NULL)
      })
    }

    if (isTRUE(force_sign_out)) {
      # send a random uuid as the polished_session.  This will trigger a session
      # reload and a redirect to the sign in page
      return(tagList(
        tags$script(src = "polish/js/router.js?version=4"),
        tags$script(src = "polish/js/polished_session.js?version=2"),
        tags$script(paste0("polished_session('", uuid::UUIDgenerate(), "')"))
      ))
    }


    request$polished_user <- polished_user





    page_out <- NULL
    if (is.null(user)) {

      if (identical(page_query, "sign_in")) {
        # go to the sign in page
        if (is.null(sign_in_page_ui)) {

          # go to default sign in page
          page_out <- tagList(
            force(sign_in_ui_default()),
            tags$script(src = "polish/js/router.js?version=4"),
            tags$script(src = "polish/js/polished_session.js?version=2"),
            tags$script(paste0("polished_session('sign_in-", uuid::UUIDgenerate(), "')"))
          )

        } else {

          # go to custom sign in page
          page_out <- tagList(
            force(normalize_ui(sign_in_page_ui, request)),
            tags$script(src = "polish/js/router.js?version=4"),
            tags$script(src = "polish/js/polished_session.js?version=2"),
            tags$script(paste0("polished_session('sign_in-", uuid::UUIDgenerate(), "')"))
          )
        }

      } else {


        if (isFALSE(.polished$is_auth_required)) {

          # auth is not required, so allow the user to go directly to the custom shiny app
          # go to Shiny app without admin button.  User is not an admin
          page_out <- tagList(
            force(normalize_ui(ui, request)),
            tags$script(src = "polish/js/router.js?version=4"),
            tags$script(src = "polish/js/polished_session.js?version=2"),
            tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
          )
        } else {
          # send a random uuid as the polished_session.  This will trigger a session
          # reload and a redirect to the sign in page
          page_out <- tagList(
            tags$script(src = "polish/js/router.js?version=4"),
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
          tags$script(src = "polish/js/router.js?version=4"),
          tags$script(src = "polish/js/polished_session.js?version=2"),
          tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
        )
      } else if (isTRUE(user$email_verified) ||
          isFALSE(.polished$is_email_verification_required)) {

        if (isTRUE(.polished$is_two_fa_required) && isFALSE(user$two_fa_verified)) {

          page_out <- tagList(
            force(two_fa_ui()),
            tags$script(src = "polish/js/router.js?version=4"),
            tags$script(src = "polish/js/polished_session.js?version=2"),
            tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
          )

        } else {

          if (isTRUE(user$is_admin)) {

            if (identical(page_query, "admin")) {

              # go to Admin Panel
              if (is.null(custom_admin_ui)) {
                page_out <- tagList(
                  force(admin_ui(
                    options = admin_ui_options
                  )),
                  tags$script(src = "polish/js/router.js?version=4"),
                  tags$script(src = "polish/js/polished_session.js?version=2"),
                  tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
                )
              } else {
                page_out <- tagList(
                  force(normalize_ui(custom_admin_ui, request)),
                  tags$script(src = "polish/js/router.js?version=4"),
                  tags$script(src = "polish/js/polished_session.js?version=2"),
                  tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
                )
              }

            } else {

              # go to Shiny app with admin button.  User is an admin.
              page_out <- tagList(
                force(normalize_ui(ui, request)),
                custom_admin_button_ui,
                tags$script(src = "polish/js/router.js?version=4"),
                tags$script(src = "polish/js/polished_session.js?version=2"),
                tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
              )
            }


          } else {

            # go to Shiny app without admin button.  User is not an admin
            page_out <- tagList(
              force(normalize_ui(ui, request)),
              tags$script(src = "polish/js/router.js?version=4"),
              tags$script(src = "polish/js/polished_session.js?version=2"),
              tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
            )

          } # end is_admin check

        } # end 2FA check

      } else {
        # email is not verified.
        # go to email verification page

        page_out <- tagList(
          force(verify_email_ui()),
          tags$script(src = "polish/js/router.js?version=4"),
          tags$script(src = "polish/js/polished_session.js?version=2"),
          tags$script(paste0("polished_session('", user$hashed_cookie, "')"))
        )
      }


    }

    page_out
  } # end request handler function
}
