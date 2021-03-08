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
#' @param app_dir path to a directory containing R scripts or RMarkdown files. Defaults to current working directory if left blank.
#' @param verbose logical - defaults to TRUE. Will provide feedback to detected or invalid R packages.
#'
#' @return a list of package dependencies
#'
#' @keywords internal
#'
#' @seealso [automagic::parse_packages()]
#'
#' @examples
#' library(polished)
#' dir <- fs::path_package("polished", "examples", "polished_example_01")
#' pkg_deps <- polished:::get_package_deps(dir)
#'
#' @importFrom automagic get_dependent_packages get_package_details
#' @importFrom cli cli_alert_warning cli_alert_danger cat_bullet
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
  init_pkg_names <- automagic::get_dependent_packages(app_dir)

  # return if no detections
  if (length(init_pkg_names) == 0) {
    cli::cli_alert_warning("warning: no packages found in specified directory")
    return(invisible(NULL))
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
    cli::cli_alert_danger("Silently removing detected invalid packages: {errors}")
  }

  purrr::map_depth(hold, 1, purrr::pluck, "result") %>%
    purrr::map(function(x) {
      if (length(x) == 0) return(NULL) else return(x)
    }) %>%
    purrr::compact()
}
