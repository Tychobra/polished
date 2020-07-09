#' A modification of 'shiny::passwordInput'
#'
#' This modified version of shiny's passwordInput() does not actual send the password
#' to our shiny server.  It is just a regular password input that always keeps your
#' user's password on the client.  The password is used to sign the user in and then
#' converted to a JWT by Firebase, all on the client, before it is sent to your shiny
#' server.
#'
#' @param input_id The input slot that will be used to access the value.
#' @param label Display label for the control, or NULL for no label.
#' @param value Initial value.
#' @param style Character string of in-line css to style the input.
#' @param placeholder A character string giving the user a hint as to what can
#' be entered into the control. Internet Explorer 8 and 9 do not support this option.
#'
#' @importFrom htmltools tags
#'
#' @export
#'
password_input <- function(
  input_id,
  label = tagList(icon("unlock-alt"), "Password"),
  value = "",
  style = "",
  placeholder = NULL
) {
  tags$div(
    class = "form-group",
    style = style,
    tags$label(
      label,
      class = "control-label",
      class = if (is.null(label)) "shiny-label-null",
      `for` = input_id
    ),
    tags$input(
      id = input_id,
      type = "password",
      class = "form-control",
      value = value,
      placeholder = placeholder
    )
  )
}
