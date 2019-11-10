#' write js file for polished Firebase Functions
#'
#'
#' @param path "functions/index.js" by default. The file path of the created file.
#' @param overwrite TRUE by default.  Should the existing file be overwritted.
#'
#' @details By default this function will create a "functions/index.js" file which
#' contains the Polished Firebase Functions.  If you are using custom Firebase functions,
#' then change the `path` argument to something like "functions/polished.js", and make sure
#' to add `require(./polished)` in your "functions/index.js" file.
#'
#' @export
#'
#' @examples
#'
#' # must make functions folder
#' write_firebase_functions()
#'
#' write_firebase_functions("functions/my_file.js")
#'
write_firebase_functions <- function(path = "functions/index.js", overwrite = TRUE) {

  file.copy(
    from = system.file("firebase_functions/index.js", package = "polished"),
    to = path,
    overwrite = overwrite
  )
}
