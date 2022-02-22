#' A modification of \code{shiny::passwordInput}
#'
#' This modified version of Shiny's \code{passwordInput()} does not actually send the password
#' to our Shiny server.  It is just a regular password input that always keeps your
#' user's password on the client.  The password is used to sign the user in and then
#' converted to a JWT by Firebase, all on the client, before it is sent to your Shiny
#' server.
#'
#' @param input_id The \code{input} slot that will be used to access the value.
#' @param label Display label for the control, or \code{NULL} for no label.
#' @param value Initial value.
#' @param style Character string of in-line CSS to style the input.
#' @param placeholder A character string giving the user a hint as to what can
#' be entered into the control. Internet Explorer 8 and 9 do not support this option.
#'
#' @importFrom htmltools tags tagList
#'
#' @export
#'
password_input <- function(
  input_id,
  label = htmltools::tagList(icon("unlock-alt"), "Password"),
  value = "",
  style = "",
  placeholder = NULL
) {
  htmltools::tags$div(
    class = "form-group",
    style = style,
    htmltools::tags$label(
      label,
      class = "control-label",
      class = if (is.null(label)) "shiny-label-null",
      `for` = input_id
    ),
    htmltools::tags$input(
      id = input_id,
      type = "password",
      class = "form-control",
      value = value,
      placeholder = placeholder
    )
  )
}
