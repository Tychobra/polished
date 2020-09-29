

#' Sign in and register pages JavaScript dependencies
#'
#' This function should be called at the bottom of your custom sign in and registration
#' pages UI.  It loads in all the JavaScript dependencies to handle polished sign
#' in and registration.  See the vignette for details.
#'
#' @param ns the ns function from the Shiny module that this function is called
#' within.
#'
#' @importFrom htmltools tagList
#' @importFrom shinyFeedback useShinyFeedback
#'
#' @export
#'
#'
sign_in_js <- function(ns) {

  firebase_config <- .global_sessions$firebase_config

  if (is.null(firebase_config)) {
    firebase_deps <- list()
  } else {
    firebase_deps <- htmltools::tagList(
      firebase_dependencies(),
      firebase_init(firebase_config),
      tags$script(src = "polish/js/auth_firebase.js?version=3"),
      tags$script(paste0("auth_firebase('", ns(''), "')"))
    )
  }

  htmltools::tagList(
    shinyFeedback::useShinyFeedback(feedback = FALSE),
    tags$script(src = "polish/js/toast_options.js"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    firebase_deps,
    tags$script(src = "polish/js/auth_main.js?version=3"),
    tags$script(paste0("auth_main('", ns(''), "')"))
  )
}

#' Check the JWT from the user sign in
#'
#' This function retreives the JWT created by the JavaScript from \code{\link{sign_in_js}}
#' and signs the user in as long as the token can be verified.
#' This function should be called in the server function of a shiny module.  Make sure
#' to call \code{\link{sign_in_js}} in the UI function of this module.
#'
#' @param jwt a reactive returning a Firebase JSON web token for the signed in user.
#' @param session the shiny session.
#'
#' @importFrom shinyFeedback resetLoadingButton showToast
#' @importFrom shiny getDefaultReactiveDomain
#'
#' @export
#'
sign_in_check_jwt <- function(jwt, session = shiny::getDefaultReactiveDomain()) {


  observeEvent(jwt(), {
    hold_jwt <- jwt()

    tryCatch({

      if (is.null(hold_jwt$jwt)) {

        # attempt sign in with email
        new_user <- .global_sessions$sign_in_email(
          email = hold_jwt$email,
          password = hold_jwt$password,
          hashed_cookie = digest::digest(hold_jwt$cookie)
        )

        if (!is.null(new_user$message) && identical(new_user$message, "Password reset email sent")) {
          shinyFeedback::resetLoadingButton('sign_in_submit')
          shinyFeedback::showToast(
            "info",
            "Password reset required.  Check your email to reset your password.",
            .options = polished_toast_options
          )
          return()
        }

      } else {
        # attempt sign in with a social sign in provider
        new_user <- .global_sessions$sign_in_social(
          hold_jwt$jwt,
          digest::digest(hold_jwt$cookie)
        )
      }

      if (is.null(new_user)) {
        shinyFeedback::resetLoadingButton('sign_in_submit')
        # show unable to sign in message
        shinyFeedback::showToast(
          'error',
          'sign in error',
          .options = polished_toast_options
        )
        stop('sign_in_module: sign in error', call. = FALSE)

      } else {
        # sign in success
        remove_query_string()
        session$reload()
      }

    }, error = function(err) {
      shinyFeedback::resetLoadingButton('sign_in_submit')
      print(err)

      shinyFeedback::showToast(
        "error",
        err$message,
        .options = polished_toast_options
      )

    })

  })
}
