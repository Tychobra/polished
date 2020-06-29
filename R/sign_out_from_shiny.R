#' sign_out_from_shiny
#'
#' Call this function to sign a user out of your 'shiny' app.  This function should
#' be called inside the server function of your 'shiny' app.  See
#' \url{https://github.com/Tychobra/polished/blob/master/inst/examples/polished_example_01/server.R}
#' For an example of this function being called after the user clicks a "Sign Out"
#' button.
#'
#' @param session the Shiny session
#'
#' @export
#'
#' @importFrom shiny updateQueryString getDefaultReactiveDomain
#'
#'
#'
sign_out_from_shiny <- function(session = shiny::getDefaultReactiveDomain()) {

  user <- session$userData$user()

  if (is.null(user)) stop("session$userData$user() does not exist", call. = FALSE)

  # sign the user out of polished
  .global_sessions$sign_out(user$hashed_cookie, user$session_uid)

  # set query string to sign in page
  shiny::updateQueryString(
    queryString = paste0("?page=sign_in"),
    session = session,
    mode = "replace"
  )

}
