#' write_log
#'
#' @param req the API request
#' @param type the log type.  Valid values are "request", "info", and "error"
#' @param message a custom message to include with the log
#'
#' @return JSON formatted character string of the log message
#'
write_log <- function(req, type = "request", message = "") {


  log_msg <- jsonlite::toJSON(
    list(
      request_method = req$REQUEST_METHOD,
      path_info      = req$PATH_INFO,
      account_uid    = req$account_uid,
      user_uid       = req$user_uid,
      app_uid        = req$app_uid,
      type           = type,
      message        = message
    )
  )


  cat(
    log_msg,
    "\n"
  )
}
