#' sign_out_from_shiny
#'
#' @param session the Shiny session
#'
#' @import shiny
#'
#' @export
#'
sign_out_from_shiny <- function(session) {

  # remove the user from `global_users`
  token <- shiny::parseQueryString(session$clientData$url_search)$token
  .global_users$remove_user_by_token(token)

  # update the query string
  shiny::updateQueryString(
    queryString = "?sign_out=true",
    session = session,
    mode = "replace"
  )

  # sign out from Firebase on client side
  session$sendCustomMessage(
    "polish__sign_out",
    message = list()
  )

  session$reload()
}
