#' create a uid
#'
#' user for the uids in the database
#'
#' @param n length 1 integer > 0.  The number of uids to create.
#'
#' @return a character string uid
#'
#' @importFrom stats runif
#'
#' @export
#'
#' @examples
#'
#' # create a single uid
#' create_uid()
#'
#' # create 10 uids
#' create_uid(10)
#'
create_uid <- function(n = 1) {
  stopifnot(length(n) == 1)
  stopifnot(n > 0)


  paste0(
    "p",
    vdigest(runif(n))
  )
}

#' vectorize the
#'
#' @importFrom digest digest
#'
#' @noRd
vdigest <- Vectorize(digest::digest)
