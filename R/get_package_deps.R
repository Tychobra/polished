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
#' @param app_dir path to a directory containing R scripts or R Markdown files. Defaults
#' to current working directory.
#' @param all_deps boolean - whether or not to explicitly identify all "Imports" package dependencies
#' of the packages used by your app.
#'
#' @return a list of package dependencies with installation details
#'
#' @keywords internal
#'
#' @seealso [automagic::parse_packages()]
#'
#' @examples
#' app_dir <- "inst/examples/polished_example_01"
#' #pkg_deps <- polished::get_package_deps("inst/examples/polished_example_01")
#'
#' @importFrom desc desc_get_deps
#' @importFrom automagic parse_packages get_package_details
#' @importFrom dplyr %>%
#'
get_package_deps <- function(
  app_dir = ".",
  all_deps = FALSE
) {

  # validate args
  if (!dir.exists(app_dir)) {
    stop(paste0("Invalid path argument. '", app_dir, "' does not exist."))
  }

  # detect R package dependencies
  fls <- list.files(
    path = app_dir,
    pattern = '^.*\\.R$|^.*\\.Rmd$',
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )

  pkg_names <- unlist(lapply(fls, automagic::parse_packages))
  pkg_names <- sort(unique(pkg_names))

  if (isTRUE(all_deps)) {
    pkg_names_start <- pkg_names
    pkg_names_end <- character(0)
    while (TRUE) {

      # get all the Imports package dependencies of identified packages
      deps_deps <- lapply(pkg_names_start, function(name_) {
        desc::desc_get_deps(file = system.file("/", package = name_))
      })

      deps_deps <- dplyr::bind_rows(deps_deps)
      deps_deps <- deps_deps[deps_deps$type %in% c("Depends", "Imports", "LinkingTo"), ]$package
      pkg_names_end <- unique(c(pkg_names_start, deps_deps))
      pkg_names_end <- pkg_names_end[pkg_names_end != "R"]
      pkg_names_end <- sort(pkg_names_end)

      if (identical(pkg_names_end, pkg_names_start)) {
        break
      }
      pkg_names_start <- pkg_names_end
    }

    pkg_names <- pkg_names_end
  }





  # validate packages.  `automagic::get_package_details` will throw an error if the
  # package is not on CRAN or in a public GitHub repo.
  out <- list()

  for (name_ in  pkg_names) {

    hold <- automagic::get_package_details(name_)

    # will remove any base R packages
    if (!is.null(hold)) {
      out[[hold$Package]] <- hold
    }
  }

  out
}

# desc_file_deps <- function(pkg_names) {
#   if (isTRUE(all_deps)) {
#     # get all the Imports package dependencies of identified packages
#     deps_deps <- lapply(pkg_names, function(name_) {
#       desc::desc_get_deps(file = system.file("/", package = name_))
#     })
#
#     deps_deps <- dplyr::bind_rows(deps_deps)
#     deps_deps <- deps_deps[deps_deps$type %in% c("Depends", "Imports", "LinkingTo"), ]$package
#     pkg_names <- unique(c(pkg_names, deps_deps))
#     pkg_names <- pkg_names[pkg_names != "R"]
#   }
#
#   sort(pkg_names)
# }
