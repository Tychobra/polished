#' get last active session time
#'
#' find the time that the last session became active for all users of a particular app
#'
#' @param conn the database connection
#' @param app_uid the uid of the app
#' @param schema the database schema
#'
#' @importFrom dplyr tbl filter collect group_by summarize ungroup
#' @importFrom dbplyr in_schema
#' @importFrom rlang .env
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
get_last_active_session_time <- function(conn, app_uid, schema = "polished") {

  # find the most recent session for each user.  Users who have not yet signed in
  # will not have any sessions, so they won't have a row in the below data frame
  conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "sessions")) %>%
    dplyr::filter(.data$app_uid == .env$app_uid) %>%
    dplyr::collect() %>%
    dplyr::group_by(.data$user_uid) %>%
    dplyr::filter(.data$modified_at == max(.data$modified_at, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    select(
      session_uid = .data$uid,
      .data$user_uid
    )
}
