#' sign_out_from_shiny
#'
#' @param session the Shiny session
#' @param user optional user list.  A list containing the following elements
#' - user_uid
#' - session_uid
#' This argument is used when we need to sign the user out of polished before the
#' `session$userData$user()` reactive has been set.  e.g. we call
#' `sign_out_from_shiny(session, user = list(user_uid = <user's uid>, session_uid = <session uid>))`
#' to sign the user out of polished if there is an error in the email verification process.  If the
#' user is already signed into the app (i.e. the `session$userData$user()` is set), then this argument
#' should be NULL and we can grab the user_uid and session_uid from the `session$userData$user()` object.
#'
#' @export
#'
sign_out_from_shiny <- function(session, user = NULL) {

  if (is.null(user)) {
    user <- session$userData$user()
  }

  if (is.null(user)) stop("session$userData$user() does not exist")

  # remove the user from `global_users`
  .global_sessions$sign_out(user$user_uid, user$session_uid)

  # set query string to sign in page
  shiny::updateQueryString(
    queryString = paste0("?page=sign_in"),
    session = session,
    mode = "replace"
  )

}
