#' sign_out_from_shiny
#'
#' @param session the Shiny session
#'
#' @export
#'
sign_out_from_shiny <- function(session) {

  user <- session$userData$user()

  if (is.null(user)) stop("session$userData$user() does not exist")

  # remove the user from `global_users`
  .global_sessions$sign_out(user$hashed_cookie, user$session_uid)

  # set query string to sign in page
  shiny::updateQueryString(
    queryString = paste0("?page=sign_in"),
    session = session,
    mode = "replace"
  )

}
