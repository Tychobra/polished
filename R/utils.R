#' Remove the URL query
#'
#' Remove the entire query string from the URL.  This function should only be called
#' inside the server function of your Shiny app.
#'
#' @param session the Shiny \code{session}
#' @param mode the mode to pass to \code{shiny::updateQueryString()}.  Valid values are
#' \code{"replace"} or \code{"push"}.
#'
#' @importFrom shiny updateQueryString getDefaultReactiveDomain
#'
#' @return \code{invisible(NULL)}
#'
#' @export
#'
#'
remove_query_string <- function(session = shiny::getDefaultReactiveDomain(), mode = "replace") {

  shiny::updateQueryString(
    "/",
    mode = mode,
    session = session
  )

  invisible(NULL)
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
#'
get_cookie <- function(cookie_string, name) {

  cookies <- strsplit(cookie_string , split = "; ", fixed = TRUE)

  tibble::tibble(cookie = unlist(cookies)) %>%
    tidyr::separate(.data$cookie, into = c("key", "value"), sep = "=", extra = "merge") %>%
    dplyr::filter(.data$key == name) %>%
    dplyr::pull("value")
}



#' create UI for checkbox to send an email invite
#'
#' @param ns the Shiny namespace function
#' @param app_url the app url
#'
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

#' normalize UI
#'
#' the UI passed a shiny app can be a function HTML.  This function normalized the 2 different
#' formats so that they both use the character
#'
#' @param ui the Shiny ui
#' @param request_ the request environment passed to the first argument of the UI
#' function
#'
#' @export
#'
#' @return the Shiny UI
#'
normalize_ui <- function(ui, request_) {
  if (is.function(ui)) {
    if (length(formals(ui)) > 0) {
      ui <- ui(request_)
    }  else {
      ui <- ui()
    }
  } else {
    ui <- ui
  }
  ui
}

# Default `.options` for `showToast`
polished_toast_options <- list(
  positionClass = "toast-top-center",
  showDuration = 1000,
  newestOnTop = TRUE
)

#' is_valid_email
#'
#' function for email validation (Sign in & Registration)
#'
#' @param x email address to check
#'
#' @noRd
#'
is_valid_email <- function(x) {
  grepl("^\\s*[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\s*$", as.character(x), ignore.case=TRUE)
}


#' is_email_registered
#'
#' Check if an email address is already registered.  This function is used in our
#' sign in modules to redirect the user from the sign in inputs to the registration
#' inputs if the user is attempting to sign in before they have registered.
#'
#' @param email the email address to check
#'
#' @return a list with the a boolean element named "is_registered", and an "error"
#' element if there is an error status code returned from the Polished Auth API request.
#'
#' @noRd
#'
is_email_registered <- function(email) {

  user_res <- httr::GET(
    paste0(.polished$api_url, "/users"),
    query = list(
      email = email
    ),
    httr::authenticate(
      user = get_api_key(),
      password = ""
    )
  )

  user_res_content <- jsonlite::fromJSON(
    httr::content(user_res, "text", encoding = "UTF-8")
  )

  if (!identical(httr::status_code(user_res), 200L)) {
    out <- list(
      is_registered = FALSE,
      error = user_res_content
    )
  } else {
    if (isTRUE(user_res_content$is_password_set)) {
      out <- list(
        is_registered = TRUE
      )

    } else {
      out <- list(
        is_registered = FALSE
      )
    }
  }


  out
}
