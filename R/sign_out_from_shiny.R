#' sign_out_from_shiny
#'
#' @param session the Shiny session
#'
#' @import shiny
#'
#' @export
#'
sign_out_from_shiny <- function(session) {

  shiny::updateQueryString(
    queryString = "?sign_out=true",
    session = session,
    mode = "replace"
  )

  # remove the user from `global_users`
  token <- shiny::parseQueryString(session$clientData$url_search)$token

  .global_users$remove_user_by_token(token)

  session$reload()
}
