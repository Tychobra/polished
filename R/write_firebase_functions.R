#' write the index.js file
#' 
#' @param path The file path of the created file
#' 
#' @export
#' 
#' @examples 
#' 
#' #must make functions folder
#' write_firebase_functions()
#' 
#' write_firebase_functions("inst")
#' 
write_firebase_functions <- function(path = "functions/index.js") {
  
  file.copy(
    from = system.file("inst/firebase_functions/index.js", package = "polished"),
    to = path
  )
}
