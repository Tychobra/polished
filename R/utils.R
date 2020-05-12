#' remove_query_string
#'
#' Remove the entire query string
#'
#' @param session the Shiny session
#'
#' @export
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
#' @importFrom dplyr filter pull %>%
#' @importFrom tidyr separate
#' @importFrom tibble tibble
#'
#' @export
#'
#' @examples
#' cookies <- "cookie_name=cookie-value; cookie_name_2=cookie-value-2; cookie_name_3=cookie-with=sign"
#'
#' get_cookie(cookies, "cookie_name")
#' get_cookie(cookies, "cookie_name_2")
#' get_cookie(cookies, "cookie_name_3")
#'
get_cookie <- function(cookie_string, name) {

  cookies <- strsplit(cookie_string , split = "; ", fixed = TRUE)

  tibble::tibble(cookie = unlist(cookies)) %>%
    tidyr::separate(.data$cookie, into = c("key", "value"), sep = "=", extra = "merge") %>%
    dplyr::filter(.data$key == name) %>%
    dplyr::pull("value")
}


#' @importFrom lubridate with_tz
time_now_utc <- function() {
  lubridate::with_tz(Sys.time(), tzone = "UTC")
}

