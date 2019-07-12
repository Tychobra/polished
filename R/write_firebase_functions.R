#' write the index.js file
#'
#' @param path "functions/index.js" by default. The file path of the created file.
#' @param overwrite TRUE by default.  Should the existing file
#' be overwritted
#'
#' @export
#'
#' @examples
#'
#' # must make functions folder
#' write_firebase_functions()
#'
#' write_firebase_functions("inst")
#'
write_firebase_functions <- function(path = "functions/index.js", overwrite = TRUE) {

  file.copy(
    from = system.file("firebase_functions/index.js", package = "polished"),
    to = path,
    overwrite = overwrite
  )
}
