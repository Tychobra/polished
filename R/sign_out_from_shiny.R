#' sign_out_from_shiny
#'
#' @param session the Shiny session
#'
#' @import shiny
#'
#' @export
#'
sign_out_from_shiny <- function(session) {

  user <- session$userData$current_user()

  # remove the user from `global_users`
  .global_users$remove_user_by_uid(user$uid, user$polished_session)

  # remove any existing query string
  remove_query_string(session)

  # sign out from Firebase on client side
  session$sendCustomMessage(
    "polish__sign_out",
    message = list()
  )

}
