#' create a uid
#'
#' user for the uids in the database
#'
#' @return a character string uid
#'
#' @importFrom digest digest
#' @importFrom stats runif
#'
create_uid <- function() {

  paste0("p", digest::digest(c(runif(1), Sys.time())))
}
