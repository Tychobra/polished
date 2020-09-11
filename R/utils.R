#' Remove the URL query
#'
#' Remove the entire query string from the url.  This function should only be called
#' inside the server function of your 'shiny' app.
#'
#' @param session the Shiny session
#'
#' @importFrom shiny updateQueryString getDefaultReactiveDomain
#'
#' @export
#'
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
#' @importFrom rlang .data
#'
#' @noRd
#'
#' @examples
#' cookies <- "cookie_name=cookie-value; cookie_name_2=cookie-value-2; cookie_name_3=cookie-with=sign"
#'
#' polished:::get_cookie(cookies, "cookie_name")
#' polished:::get_cookie(cookies, "cookie_name_2")
#' polished:::get_cookie(cookies, "cookie_name_3")
#'
get_cookie <- function(cookie_string, name) {

  cookies <- strsplit(cookie_string , split = "; ", fixed = TRUE)

  tibble::tibble(cookie = unlist(cookies)) %>%
    tidyr::separate(.data$cookie, into = c("key", "value"), sep = "=", extra = "merge") %>%
    dplyr::filter(.data$key == name) %>%
    dplyr::pull("value")
}


#' @noRd
#'
#' @importFrom lubridate with_tz
time_now_utc <- function() {
  lubridate::with_tz(Sys.time(), tzone = "UTC")
}

#' @noRd
#'
#' @importFrom shinyjs disabled
#' @importFrom shinyWidgets prettyCheckbox
#' @importFrom htmltools tags
send_invite_checkbox <- function(ns, app_url) {
  # check if the app has an app url.  If the app has an app_url, allow the
  # user to send an invite email.
  if (!is.null(app_url) && !is.na(app_url) && app_url != "") {
    email_invite_checkbox <- shinyWidgets::prettyCheckbox(
      ns("send_invite_email"),
      "Send Invite Email?",
      value = FALSE,
      status = "primary"
    )
  } else {
    email_invite_checkbox <- tags$div(
      tags$span(
        shinyjs::disabled(shinyWidgets::prettyCheckbox(
          ns("send_invite_email"),
          "Send Invite Email?",
          value = FALSE,
          status = "primary",
          inline = TRUE
        ))
      ),
      tags$span(
        style = "display: inline-block; margin-left: -15px;",
        id = ns("checkbox_question"),
        icon("question-circle"),
        `data-toggle` = "tooltip",
        `data-placement`= "top",
        title = "You must set the App URL to send email invites. Go to https://dashboard.polished.tech to set your app URL."
      )
    )
  }

  email_invite_checkbox
}