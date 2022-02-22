#' A Shiny email \code{input}
#'
#' This is a replica of \code{shiny::textInput()} with the HTML input \code{type}
#' attribute set to \code{"email"} rather than \code{"text"}.
#'
#' @param inputId The \code{input} slot that will be used to access the value.
#' @param label Display label for the control, or \code{NULL} for no label.
#' @param value Initial value.
#' @param width The width of the input, e.g. \code{'400px'}.
#' @param placeholder A character string giving the user a hint as to what can be entered
#' into the control. Internet Explorer 8 and 9 do not support this option.
#'
#' @export
#'
#' @importFrom htmltools tags tagList
#' @importFrom shiny restoreInput icon
#'
email_input <- function(
  inputId,
  label = tagList(shiny::icon("envelope"), "Email"),
  value = "",
  width = NULL,
  placeholder = NULL
) {
  value <- shiny::restoreInput(id = inputId, default = value)

  htmltools::tags$div(
    class = "form-group shiny-input-container",
    style = if (!is.null(width)) paste0("width: ", width, ";"),
    htmltools::tags$label(
      label,
      class = "control-label",
      class = if (is.null(label)) "shiny-label-null",
      `for` = inputId
    ),
    htmltools::tags$input(
      id = inputId,
      type = "email",
      class = "form-control",
      value = value,
      placeholder = placeholder
    )
  )
}

