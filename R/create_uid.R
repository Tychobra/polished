#' create a uid(s)
#'
#' @param n length 1 integer > 0.  The number of uids to create.
#'
#' @return a character vector of uids
#'
#' @importFrom uuid UUIDgenerate
#' @importFrom purrr map_chr
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

  purrr::map_chr(seq_len(n), uuid::UUIDgenerate)
}


