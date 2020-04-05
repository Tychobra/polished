#' get last active session time
#'
#' find the time that the last session became active for all users of a particular app
#'
#' @param conn the database connection
#' @param app_uid_ the uid of the app
#' @param schema the database schema
#'
#' @importFrom dplyr tbl filter collect group_by summarize ungroup
#' @importFrom dbplyr in_schema
#'
#' @return a data frame with 2 columns:
#' - user_uid
#' - timestamp
#' The timestamps in this dataframe mark the most recent time that the user
#' has accessed the app.  Users without a row in this table have not yet accessed the
#' app
#'
#' @export
#'
#'
#'
get_last_active_session_time <- function(conn, app_uid_, schema = "polished") {

  # find the most recent session for each user.  Users who have not yet signed in
  # will not have any sessions, so they won't have a row in the `last_user_app_sessions` table
  last_user_app_sessions <- conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "sessions")) %>%
    dplyr::filter(.data$app_uid == app_uid_) %>%
    dplyr::collect() %>%
    dplyr::group_by(.data$user_uid) %>%
    dplyr::filter(.data$created_at == max(.data$created_at, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    select(
      session_uid = .data$uid,
      .data$user_uid
    )

  session_uids <- last_user_app_sessions$session_uid

  # find the timestamp of the most recent time each user has accesses the app.
  # This timestamp is the 'last active session time'
  last_active_times <- conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, 'session_actions')) %>%
    dplyr::filter(
      .data$session_uid %in% session_uids,
      .data$action == 'activate'
    ) %>%
    dplyr::group_by(.data$session_uid) %>%
    dplyr::filter(.data$timestamp == max(.data$timestamp, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::collect() %>%
    select(.data$session_uid, .data$timestamp)

  last_user_app_sessions %>%
    left_join(last_active_times, by = 'session_uid') %>%
    select(.data$user_uid, last_sign_in_at = .data$timestamp)
}
