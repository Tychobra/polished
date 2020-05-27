
#' get session by hashed cookie
#'
#' @param conn the database connection
#' @param account_uid the account uid
#' @param hashed_cookie the hashed cookie
#' @param app_uid the id of the app
#' @param schema the database schema
#'
#' @importFrom DBI dbGetQuery
#' @importFrom dplyr filter
#' @importFrom rlang .env
#'
#' @export
#'
#' @return the signed in user session
#'
#'
get_session <- function(conn, account_uid, hashed_cookie, app_uid, schema = "polished") {

  signed_in_sessions <- DBI::dbGetQuery(
    conn,
    paste0('SELECT uid AS session_uid, user_uid, email, email_verified, app_uid, signed_in_as FROM ',
    schema, '.sessions WHERE hashed_cookie=$1 AND is_signed_in=$2 AND account_uid=$3'),
    params = list(
      hashed_cookie,
      TRUE,
      account_uid
    )
  )

  session_out <- NULL
  if (nrow(signed_in_sessions) > 0) {

    # confirm that user is invited
    invite <- get_invite(
      conn,
      app_uid,
      signed_in_sessions$user_uid[1],
      schema = schema
    )

    if (is.null(invite)) {
      return(NULL)
    }

    session_out <- list(
      "user_uid" = signed_in_sessions$user_uid[1],
      "email" = signed_in_sessions$email[1],
      "email_verified" = signed_in_sessions$email_verified[1],
      "is_admin" = invite$is_admin,
      "hashed_cookie" = hashed_cookie
    )

    app_session <- signed_in_sessions %>%
      dplyr::filter(.data$app_uid == .env$app_uid)

    if (nrow(app_session) == 0) {
      # user was signed into another app and came over to this app, so add a session for this app
      session_out$session_uid <- uuid::UUIDgenerate()

      add_session(conn, session_out, app_uid, schema = schema)

      session_out$signed_in_as <- NA
    } else if (nrow(app_session) == 1) {

      session_out$session_uid <- app_session$session_uid
      session_out$signed_in_as <- app_session$signed_in_as
    } else {
      stop('error: too many sessions', call. = FALSE)
    }
  }

  session_out
}
