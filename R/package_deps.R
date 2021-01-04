#' Get/Detect R Package Dependencies
#'
#' Given a `path` to a directory/shinyAppDir this function will scan all `.R` and
#' `.Rmd` files for any used R Packages along with their versions/Github references.
#'
#' @details Currently, detections are made via [automagic::parse_packages()] which supports
#'   the following calls within the code: `library()`, `require()`, and
#'   prefixed `::` calls to functions.
#'
#'   Once an initial vector of package detections is built, it is further processed by
#'   validating that each detection is indeed a valid `CRAN` or public `Github` package
#'   and can be installed.
#'
#' @param path path to a directory containing R scripts or RMarkdown files. Defaults to current working directory if left blank.
#' @param write_yaml logical - should a `deps.yaml` file be created at specified path?
#' @param verbose logical - defaults to TRUE. Will provide feedback to detected or invalid R packages.
#'
#' @return silently returns a `data.frame` with detected R package details
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
#' @importFrom automagic get_dependent_packages parse_packages
#' @importFrom cli cli_alert_warning cli_ul cat_bullet
#' @importFrom dplyr bind_rows mutate select
#' @importFrom fs dir_exists path_abs
#' @importFrom purrr safely map_depth pluck compact map
#' @importFrom yaml write_yaml
get_package_deps <- function(path,
                             write_yaml = TRUE,
                             verbose = TRUE) {

  # validate args
  if (missing("path")) path <- getwd()
  if (!fs::dir_exists(path)) stop(paste0("Invalid path argument. '", fs::path_abs(path), "' does not exist."))

  # get initial detections from automagic:::get_dependent_packages()
  init_pkg_names <- automagic:::get_dependent_packages(path)

  # return if no detections
  if (length(init_pkg_names) == 0) {
    cli::cli_alert_warning("warning: no packages found in specified directory")
    return(invisible(NULL))
  }

  # validate packages
  hold <- lapply(init_pkg_names,
                 purrr::safely(automagic:::get_package_details, quiet = verbose))
  names(hold) <- init_pkg_names

  errors <- purrr::map_depth(hold, 1, purrr::pluck, "error") %>%
    purrr::compact() %>%
    names()

  hold <- hold[!(names(hold) %in% errors)]

  if (length(errors) > 0 && verbose) {
    cli::cli_alert_warning("Silently removing detected invalid packages:")
    cli::cli_ul(errors)
  }

  out <- purrr::map_depth(hold, 1, purrr::pluck, "result") %>%
    purrr::map(function(x) {
      if (length(x) == 0) return(NULL) else return(x)
    }) %>%
    purrr::compact()

  if (write_yaml) {
    yml_path <- file.path(path, "deps.yaml")
    yaml::write_yaml(out, yml_path)
    cli::cat_bullet(
      "Created file `deps.yaml`.",
      bullet = "tick",
      bullet_col = "green"
    )
  }

  df <- dplyr::bind_rows(out) %>%
    dplyr::mutate(
      Repository = ifelse(is.na(.data$Repository), "Github", .data$Repository),
      install_cmd = ifelse(
        .data$Repository == "CRAN",
        paste0(
          "remotes::install_version(",
          shQuote(.data$Package),
          ", version = ",
          shQuote(.data$Version),
          ")"
        ),
        paste0(
          "remotes::install_github(",
          shQuote(paste0(.data$GithubUsername, "/", .data$Package)),
          ", ref = ",
          shQuote(.data$GithubSHA1),
          ")"
        )
      )
    ) %>% dplyr::select(package = .data$Package,
                        src = .data$Repository,
                        version = .data$Version,
                        .data$install_cmd)

  return(invisible(df))

}

