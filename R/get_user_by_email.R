#' get user by email address
#'
#' @param conn_ the database connection
#' @param email the user's email address
#'
#' @return a list of user info if the user is found or `NULL`
#'
#' @export
#'
#' @importFrom DBI dbGetQuery
#'
get_user_by_email <- function(conn_, email) {
  user_out <- DBI::dbGetQuery(
    conn_,
    "SELECT * FROM polished.users WHERE email=$1",
    params = list(
      email
    )
  )

  if (nrow(user_out) == 0) {
    return(NULL)
  }

  as.list(user_out)
}
