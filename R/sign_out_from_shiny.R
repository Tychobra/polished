#' sign_out_from_shiny
#'
#' @param session the Shiny session
#'
#'
#' @export
#'
sign_out_from_shiny <- function(session) {

  user <- session$userData$user()

  # remove the user from `global_users`
  .global_sessions$sign_out(user$user_uid, user$session_uid)

  # set query string to sign in page
  shiny::updateQueryString(
    queryString = paste0("?page=sign_in"),
    session = session,
    mode = "replace"
  )

}
