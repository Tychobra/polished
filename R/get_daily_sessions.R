#' get daily sessions
#'
#' @param conn the database connection
#' @param app_uid_ the app id
#' @param start_date the start date for the query
#' @param schema the database schema
#'
#' @importFrom dbplyr in_schema
#' @importFrom dplyr filter select collect mutate group_by ungroup summarize left_join
#'
#' @export
#'
get_daily_sessions <- function(
  conn,
  app_uid_,
  start_date,
  schema = "polished"
) {

  # find all sessions for this app
  dat_sessions <- conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "sessions")) %>%
    dplyr::filter(.data$app_uid == app_uid_) %>%
    dplyr::select(.data$user_uid, .data$email, .data$is_active, .data$uid) %>%
    collect()

  app_sessions <- dat_sessions$uid

  dat_actions <- conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "session_actions")) %>%
    dplyr::filter(
      .data$action == "activate",
      .data$timestamp >= start_date,
      .data$session_uid %in% app_sessions
    ) %>%
    dplyr::select(.data$session_uid, .data$timestamp) %>%
    dplyr::collect() %>%
    dplyr::mutate(date = as.Date(.data$timestamp, tz = "America/New_York"))

  out <- dat_actions %>%
    left_join(dat_sessions, by = c("session_uid" = "uid")) %>%
    dplyr::group_by(.data$date, .data$user_uid) %>%
    dplyr::summarize(n = dplyr::n()) %>%
    dplyr::ungroup()

  if (nrow(out) > 0) {
    # make sure all days are included even if zero sessions in a day
    first_day <- min(out$date)

    all_days <- tibble::tibble(
      date = seq.Date(
        from = first_day,
        to = lubridate::today(tzone = "America/New_York"),
        by = "day"
      )
    )

    out <- all_days %>%
      dplyr::left_join(out, by = "date") %>%
      mutate(n = ifelse(is.na(n), 0, n))
  }

  out
}