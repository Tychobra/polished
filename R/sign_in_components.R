

#' Sign in and register pages JavaScript dependencies
#'
#' This function should be called at the bottom of your custom sign in and registration
#' pages UI.  It loads in all the javascript dependencies to handle polished sign
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
sign_in_js <- function(ns, include_default_keystrokes = TRUE) {

  firebase_config <- .global_sessions$firebase_config

  htmltools::tagList(
    shinyFeedback::useShinyFeedback(feedback = FALSE),

    firebase_dependencies(),
    firebase_init(firebase_config),
    tags$script(src = "polish/js/toast_options.js"),
    tags$script(src = "polish/js/auth_all.js?version=1"),
    if (isTRUE(include_default_keystrokes)) tags$script(paste0("auth_all('", ns(''), "')")) else list(),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    tags$script(src = "polish/js/auth_firebase.js?version=6"),
    tags$script(paste0("auth_firebase('", ns(''), "')"))
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
#' @importFrom shinyWidgets sendSweetAlert
#' @importFrom shiny getDefaultReactiveDomain
#'
#' @export
#'
sign_in_check_jwt <- function(jwt, session = shiny::getDefaultReactiveDomain()) {


  observeEvent(jwt(), {
    hold_jwt <- jwt()

    tryCatch({

      # user is invited, so attempt sign in
      new_user <- .global_sessions$sign_in(
        hold_jwt$jwt,
        digest::digest(hold_jwt$cookie)
      )

      if (is.null(new_user)) {
        shinyFeedback::resetLoadingButton('submit_sign_in')
        # show unable to sign in message
        shinyFeedback::showToast('error', 'sign in error')
        stop('sign_in_module: sign in error', call. = FALSE)

      } else {
        # sign in success
        remove_query_string()
        session$reload()
      }

    }, error = function(e) {
      shinyFeedback::resetLoadingButton('submit_sign_in')
      print(e)
      shinyWidgets::sendSweetAlert(
        session,
        title = "Not Authorized",
        text = "You must have an invite to access this app",
        type = "error"
      )

    })

  })
}
