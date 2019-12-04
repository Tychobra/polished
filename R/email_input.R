#' email input
#'
#' set the "type" of the input tag to "email" rather than "text" to get the
#' correct email input browser behavior
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Display label for the control, or NULL for no label.
#' @param value Initial value.
#' @param width The width of the input, e.g. '400px'.
#' @param placeholder A character string giving the user a hint as to what can be entered
#' into the control. Internet Explorer 8 and 9 do not support this option.
#'
#' @export
#'
#' importFrom htmltools tags
#' importFrom shiny restoreInput
#'
email_input <- function (inputId, label, value = "", width = NULL, placeholder = NULL) {
  value <- shiny::restoreInput(id = inputId, default = value)

  tags$div(
    class = "form-group shiny-input-container",
    style = if (!is.null(width))
    paste0("width: ", width, ";"),
    tags$label(
      label,
      class = "control-label",
      class = if (is.null(label)) "shiny-label-null",
      `for` = inputId
    ),
    tags$input(
      id = inputId,
      type = "email",
      class = "form-control",
      value = value,
      placeholder = placeholder
    )
  )
}
