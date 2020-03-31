
#' get session by hashed cookie
#'
#' @param hashed_cookie the hashed cookie
#'
#' @importFrom DBI dbGetQuery
#'
#' @return the signed in user session
#'
#'
get_session <- function(conn_, hashed_cookie) {

  DBI::dbGetQuery(
    conn_,
    'SELECT uid AS session_uid, user_uid, email, email_verified, app_name, signed_in_as FROM
    polished.sessions WHERE hashed_cookie=$1 AND is_signed_in=$2',
    params = list(
      hashed_cookie,
      TRUE
    )
  )
}
