#' remove_query_string
#'
#' Remove the entire query string
#'
#' @param session the Shiny session
#'
#' @importFrom shiny updateQueryString getDefaultReactiveDomain
#'
remove_query_string <- function(session = shiny::getDefaultReactiveDomain()) {

  shiny::updateQueryString(
    session$clientData$url_pathname,
    mode = "replace",
    session = session
  )
}

#' get_cookie
#'
#' Get a cookie value by name from a cookie string
#'
#' @param cookie_string the cookie string
#' @param name the name of the cookie
#'
#' @import dplyr
#' @import tidyr
#'
#' @examples
#' cookies <- "_ga=GA1.1.768093326.1554508951; PGADMIN_KEY=a20922d4-e598-42e8-b62c-a9c9f833d249; PGADMIN_LANGUAGE=en"
#'
#' get_cookie(cookies, "_ga")
#'
get_cookie <- function(cookie_string, name) {

  cookies <- strsplit(cookie_string , split = "; ", fixed = TRUE)

  dplyr::tibble(cookie = unlist(cookies)) %>%
    tidyr::separate(cookie, into = c("key", "value"), sep = "=", extra = "merge") %>%
    dplyr::filter(key == name) %>%
    dplyr::pull("value")
}


#' convert_timestamp
#'
#' convert a Javascript JSON UTC date to a time in R.  We generally convert
#' Firestore timestamps to JSON UTC dates before we send them to R.
#'
#' @param timestamp the JSON UTC date(s)
#' @param tz the timezone to convert the returned datetime to
#'
#' @importFrom lubridate force_tz
#'
#' @return the R POSIX.ct datetime(s)
#'
#'
#' @export
#'
#' @examples
#'
#' json_times <- "2019-07-17T21:10:48.245Z"
#'
#' convert_timestamp(json_times)
#'
convert_timestamp <- function(timestamp, tz = "America/New_York") {

  out <- as.POSIXct(timestamp, format="%Y-%m-%dT%H:%M:%S", tz = "UTC")

  lubridate::with_tz(out, tzone = tz)
}
