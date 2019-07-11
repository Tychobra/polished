#' sign_out_from_shiny
#'
#' @param session the Shiny session
#' @param token the user's JWT
#'
#' @import shiny
#'
#' @export
#'
sign_out_from_shiny <- function(session, token) {

  # remove the user from `global_users`
  .global_users$remove_user_by_token(token)

  # remove any existing query string
  remove_query_string(session)

  # sign out from Firebase on client side
  session$sendCustomMessage(
    "polish__sign_out",
    message = list()
  )

  session$reload()
}
