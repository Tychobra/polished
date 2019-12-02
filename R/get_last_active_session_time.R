#' get last active session time
#'
#' find the time that the last session became active for all users of a particular app
#'
#' @param conn the database connection
#'
#' @importFrom dplyr tbl filter collect group_by summarize ungroup
#' @importFrom dbplyr in_schema
#'
#' @export
#'
#'
#'
get_last_active_session_time <- function(conn, app_name_) {

  last_user_app_sessions <- conn %>%
    dplyr::tbl(dbplyr::in_schema('polished', 'sessions')) %>%
    dplyr::filter(.data$app_name == app_name_) %>%
    dplyr::collect() %>%
    dplyr::group_by(.data$user_uid) %>%
    dplyr::filter(created_at == max(.data$created_at, na.rm = TRUE)) %>%
    dplyr::ungroup()

  session_uids <- last_user_app_sessions$uid

  last_active_times <- conn %>%
    dplyr::tbl(dbplyr::in_schema('polished', 'session_actions')) %>%
    dplyr::filter(
      .data$session_uid %in% session_uids,
      .data$action == 'activate'
    ) %>%
    dplyr::group_by(.data$session_uid) %>%
    dplyr::filter(timestamp == max(.data$timestamp, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::collect()

  last_user_app_sessions %>%
    left_join(last_active_times, by = c('uid' = 'session_uid'))
}
