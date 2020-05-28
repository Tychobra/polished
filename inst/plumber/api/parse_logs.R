




parse_logs <- function(logs_vec) {
  dat <- lapply(logs_vec, function(log_msg) {

    out <- NULL
    tryCatch({
      out <- jsonlite::fromJSON(log_msg)
    }, error = function(err) {
      print(err)
      # if JSON parsing fails then we will keep the original log message
      out <<- list(
        request_method = NA,
        path_info = NA,
        account_uid = NA,
        user_uid = NA,
        app_uid = NA,
        type = NA,
        message = log_msg
      )
    })


    out <- lapply(out, function(col_value) {

      if (length(col_value) == 0) {
        return(NA)
      } else {
        return(col_value)
      }

    })

    out
  })

  dat <- dplyr::bind_rows(dat) %>%
    # reorder columns
    dplyr::select(request_method, path_info, account_uid, user_uid, app_uid, type, message)
}
