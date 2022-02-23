#' Create a list of R Package Dependencies
#'
#' Given a `path` to a directory this function will scan all `.R` and
#' `.Rmd` files for any used R Packages along with their CRAN versions or GitHub references.
#'
#' @details Currently, detections are made via [automagic::parse_packages()] which supports
#'   the following calls within the code: `library()`, `require()`, and
#'   prefixed `::` calls to functions.
#'
#'   Once an initial vector of package detections is built, it is further processed by
#'   validating that each detection is indeed a valid `CRAN` or public `GitHub` package
#'   and can be installed.
#'
#' @param app_dir path to a directory containing R scripts or R Markdown files. Defaults to current working directory if left blank.
#' @param verbose boolean (default: \code{TRUE}) - Provide feedback about detected invalid R packages.
#'
#' @return a list of package dependencies
#'
#' @keywords internal
#'
#' @seealso [automagic::parse_packages()]
#'
#' @examples
#' #library(polished)
#' #dir <- system.file("examples", "polished_example_01", package = "polished")
#' #pkg_deps <- polished:::get_package_deps(dir)
#'
#' @importFrom automagic get_package_details
#' @importFrom dplyr %>%
#' @importFrom purrr safely map_depth pluck compact map
get_package_deps <- function(
  app_dir = ".",
  verbose = TRUE
) {

  # validate args
  if (!dir.exists(app_dir)) {
    stop(paste0("Invalid path argument. '", app_dir, "' does not exist."))
  }

  # detect R package dependencies
  init_pkg_names <- get_dependent_packages(app_dir)

  # return if no detections
  if (length(init_pkg_names) == 0) {
    warning("no packages found in specified directory", call. = FALSE)
    invisible(NULL)
  }


  # validate packages.  `automagic::get_package_details` will throw an error if the
  # package is not on CRAN or in a public GitHub repo.
  hold <- suppressWarnings(
    lapply(
      init_pkg_names,
      purrr::safely(
        automagic::get_package_details, quiet = TRUE
      )
    )
  )
  names(hold) <- init_pkg_names

  # check for errors
  errors <- purrr::map_depth(hold, 1, purrr::pluck, "error") %>%
    purrr::compact() %>%
    names()

  hold <- hold[!(names(hold) %in% errors)]

  if (length(errors) > 0 && verbose) {
    removed_packages <- paste(errors, collapse = ", ")
    warning(paste0("Silently removing detected invalid packages: ", removed_packages), call. = FALSE)
  }

  purrr::map_depth(hold, 1, purrr::pluck, "result") %>%
    purrr::map(function(x) {
      if (length(x) == 0) return(NULL) else return(x)
    }) %>%
    purrr::compact()
}

#' get packages required to run R code
#'
#' Note: this function is copied from the \code{automagic} R package.  We are including it in
#' \code{polished} while we await the merging of this PR \url{https://github.com/cole-brokamp/automagic/pull/17}
#' and a new CRAN release of \code{automagic}.
#'
#' @details parses all R and Rmd files in a directory and uses \code{automagic::parse_packages}
#'     to find all R packages required for the code to run
#'
#' @param directory folder to search for R and Rmd files
#'
#' @return a vector of package names
#'
#' @importFrom automagic parse_packages
#'
get_dependent_packages <- function(directory = getwd()) {

  fls <- list.files(
    path = directory,
    pattern = '^.*\\.R$|^.*\\.Rmd$',
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )

  pkg_names <- unlist(sapply(fls, automagic::parse_packages))
  pkg_names <- unique(pkg_names)

  if (length(pkg_names)==0) {
    message('warning: no packages found in specified directory')
    return(invisible(NULL))
  }

  return(unname(pkg_names))
}
