#' Adds the content of inst/srcjs/ to tychobraauth/
#'
#' @importFrom shiny addResourcePath registerInputHandler
#' @importFrom tibble tibble
#' @importFrom tidyr spread
#'
#' @noRd
#'
.onLoad <- function(...) {
  shiny::addResourcePath("polish", system.file("srcjs", package = "polishing"))

  shiny::registerInputHandler("firestore_data_frame", function(data, ...) {
    # when a collection of documents is sent from firebase to Shiny, it comes
    # as an unnamed list where each list element is a firebase document containing
    # a named list of all fields in the document.  This handler converts the Firebase
    # collection (provided as an R list) to a tibble
    data_out <- vector("list", length = length(data))
    for (i in seq_along(data_out)) {
      data_vec <- unlist(data[[i]])

      data_out[[i]] <- tibble::tibble(
        index_num = i,
        js_name = names(data_vec),
        js_value = unname(data_vec)
      )
    }

    data_out <- dplyr::bind_rows(data_out)

    tidyr::spread(data_out, key = js_name, value = js_value) %>%
      dplyr::select(-index_num)

  }, force = TRUE)
}
