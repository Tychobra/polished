get_app_sessions <- function() {

  # find all sessions for this app
  dat_sessions <- .global_sessions$conn %>%
    dplyr::tbl(dbplyr::in_schema("polished", "sessions")) %>%
    dplyr::filter(.data$app_uid == hold_app_name) %>%
    dplyr::select(.data$user_uid, .data$email, .data$is_active, .data$uid) %>%
    collect()

  app_sessions <- dat_sessions$uid

  dat_actions <- .global_sessions$conn %>%
    dplyr::tbl(dbplyr::in_schema("polished", "session_actions")) %>%
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