#' @rdname Polished
#'
#' @export
#'
polished_config <- function(
  ...
) {

  .Deprecated(
    "Polished",
    msg = "`polished_config()` is deprecated. Use the `Polished$new()` method instead"
  )

  Polished$new(...)
}


#' @rdname Polished
#'
#' @export
#'
global_sessions_config <- function(
  ...
) {

  .Deprecated(
    "Polished",
    msg = "`global_sessions_config()` is deprecated. Use the `Polished$new()` method instead"
  )

  Polished$new(...)
}