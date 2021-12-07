
valid_gcp_regions <- c(
  "asia-east1",
  "asia-east2",
  "asia-northeast1",
  "asia-northeast2",
  "asia-northeast3",
  "asia-south1",
  "asia-south2",
  "asia-southeast1",
  "asia-southeast2",
  "australia-southeast1",
  "australia-southeast2",
  "europe-north1",
  "europe-west1",
  "europe-west2",
  "europe-west3",
  "europe-west4",
  "europe-west6",
  "northamerica-northeast1",
  "northamerica-northeast2",
  "southamerica-east1",
  "southamerica-west1",
  "us-central1",
  "us-east1",
  "us-east4",
  "us-west1",
  "us-west2",
  "us-west3",
  "us-west4"
)

#' Deploy a Shiny app to Polished Hosting
#'
#' @param app_name You Shiny app's name.
#' @param app_dir The path to the directory containing your Shiny app.
#' @param api_key Your polished.tech API key.  Defaults to \code{getOption("polished")$api_key}.
#' @param launch_browser Whether or not to open your default browser to your newly deployed app
#' after it is successfully deployed.  \code{TRUE} by default.
#' @param region the region to deploy the app to on Google Cloud Platform. See
#' \url{https://cloud.google.com/run/docs/locations} for all available regions
#' on Google Cloud Platform. Currently, database connections are only supported for
#' "us-east1". See \url{https://polished.tech/docs/06-database-connections} for details.
#' @param ram_gb the amount of memory to allocate to your Shiny app server. Valid values are
#' 2, 4, or 8.
#' @param r_ver Character string of R version.  If kept as \code{NULL}, the default, then
#' \code{deploy_app()} will detect the R version you are currently running.  The R version must be a version
#' supported by an r-ver Docker image.  You can see all the r-ver Docker image versions
#' of R here \url{https://github.com/rocker-org/rocker-versioned2/tree/master/dockerfiles} and here
#' \url{https://github.com/rocker-org/rocker-versioned/tree/master/r-ver}.
#' @param tlmgr a character vector of TeX Live packages to install.  This is only used if your Shiny
#' app generates pdf documents.  Defaults to \code{character(0)} for no TeX Live installation.  Set to
#' \code{TRUE} for a minimal TeX Live installation, and pass a character vector of your TeX Live package
#' dependencies to have all your TeX Live packages installed at build time.
#' @param golem_package_name if Shiny app was created as a package with the
#' \href{"https://github.com/thinkr-open/golem"}{golem} package, provide the
#' name of the package as a character string. Defaults to \code{NULL}
#' @param cache boolean - whether or not to cache the Docker image.
#'
#' @importFrom utils browseURL
#' @importFrom httr POST authenticate status_code content upload_file
#' @importFrom jsonlite fromJSON
#'
#' @export
#'
#' @examples
#'
#' \dontrun{
#' deploy_app(
#'   app_name = "polished_example_01",
#'   app_dir = system.file("examples/polished_example_01", package = "polished"),
#'   api_key = "<your polished.tech API key>"
#' )
#' }
#'
#'
deploy_app <- function(
  app_name,
  app_dir = ".",
  api_key = getOption("polished")$api_key,
  launch_browser = TRUE,
  region = "us-east1",
  ram_gb = 2,
  r_ver = NULL,
  tlmgr = character(0),
  golem_package_name = NULL,
  cache = TRUE
) {

  if (identical(Sys.getenv("SHINY_HOSTING"), "polished")) {
    stop("You cannot run `polished::deploy_app()` from Polished Hosting.", call. = FALSE)
  }

  if (!(region %in% valid_gcp_regions)) {
    stop(paste0(
      region,
      " is not a supported region.  See all supported regions here
      https://cloud.google.com/compute/docs/regions-zones"
    ))
  }

  if (!(ram_gb %in% c(2, 4, 8))) {
    stop("`ram_db` must be 2, 4, or 8", call. = FALSE)
  }

  # check that app_dir contains either an "app.R" file or a "ui.R" and a "server.R" file
  file_names <- tolower(list.files(path = app_dir))
  if (!("app.r" %in% file_names || ("ui.r" %in% file_names && "server.r" %in% file_names)) && is.null(golem_package_name)) {
    stop('"app_dir" must contain a file named "app.R" or files named "ui.R" and "server.R"', call. = FALSE)
  } else if (!is.null(golem_package_name) && !is.character(golem_package_name)) {
    stop('"golem_package_name" must be a character string')
  }

  if (!is.logical(cache)) {
    stop("`cache` must be logical", call. = FALSE)
  }

  if (is.null(r_ver)) {
    r_ver <- paste0(R.Version()$major, ".", R.Version()$minor)
  }



  cat("Creating app bundle...")
  app_zip_path <- bundle_app(
    app_dir = app_dir
  )
  cat(" Done\n")

  cat("Deploying App.  Hang tight.  This may take a while...\n")
  if (isTRUE(launch_browser)) {
    cat("Your Shiny app will open in your default web browser once deployment is complete.\n")
  }
  cat("Deployment status can be found at https://dashboard.polished.tech")
  zip_to_send <- httr::upload_file(
    path = app_zip_path,
    type = "application/x-gzip"
  )



  url_ <- paste0(getOption("polished")$host_api_url, "/hosted-apps")
  # reset the handle.  This allows us to redeploy the app after a failed deploy.  Without
  # resetting the handle, the request sometimes does not go through.  It just sits there
  # doing nothing...
  httr::handle_reset(url = url_)

  res <- httr::POST(
    url = url_,
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    body = list(
      app_zip = zip_to_send
    ),
    query = list(
      app_name = app_name,
      region = region,
      ram_gb = ram_gb,
      r_ver = r_ver,
      tlmgr = paste(tlmgr, collapse = ","),
      golem_package_name = golem_package_name,
      cache = cache
    ),
    encode = "multipart",
    http_version = 0,
    # timeout after 30 minutes
    timeout = 1800
  )


  out <- polished_api_res(res)

  hold_status <- httr::status_code(out$response)
  if (identical(hold_status, 200L)) {
    cat(" Done\n")

    if (isTRUE(launch_browser)) {
      # launch user's browser with newly deployed Shiny app
      utils::browseURL(out$content$url)
    }
  }

  out
}


#' Create a tar archive
#'
#' This function is called by \code{deploy_app()} to compress Shiny apps before
#' deploying them to Polished Hosting.  You probably won't need to call this function
#' directly.
#'
#' @param app_dir The path to the directory containing your Shiny app.  Defaults to the
#' working directory.
#'
#' @export
#'
#' @importFrom yaml write_yaml
#' @importFrom utils tar
#' @importFrom uuid UUIDgenerate
#'
#' @examples
#'
#' \dontrun{
#' bundle_app(
#'   system.file("examples/polished_example_01", package = "polished")
#' )
#' }
#'
#'
bundle_app <- function(
  app_dir = "."
) {


  deps_list <- get_package_deps(app_dir)

  # create yaml file with all the dependencies
  yml_path <- file.path(app_dir, "deps.yaml")
  yaml::write_yaml(deps_list, yml_path)


  tar_name <- "shiny_app.tar.gz"

  temp_dir <- tempdir()
  bundles_dir <- file.path(temp_dir, uuid::UUIDgenerate())
  dir.create(bundles_dir)

  file <- file.path(bundles_dir, tar_name)


  # these folders/files will be removed before deploying app
  patterns_to_remove <- c(
    "^(?!\\.Rproj\\.user)",
    "^(?!\\.Rhistory)",
    "^(?!\\.git)"
  )

  dir_copy(
    from = app_dir,
    to = bundles_dir,
    pattern = patterns_to_remove
  )


  current_wd <- getwd()
  setwd(bundles_dir)
  on.exit({setwd(current_wd)}, add = TRUE)

  result <- utils::tar(
    tarfile = file,
    files = ".",
    compression = "gzip",
    tar = "internal"
  )

  if (result != 0) {
    stop("Failed to bundle the Shiny app.", call. = FALSE)
  }

  file
}

# the following functions are copied from the packrat R package with only minor changes.
# Original code is here: https://github.com/rstudio/packrat/blob/ae5e5abedc84ea5fc58335d9c4a17b295c6f48f7/R/utils.R#L85

is_dir <- function(file) {
  isTRUE(file.info(file)$isdir) ## isTRUE guards against NA (ie, missing file)
}

# Copy a directory at file location 'from' to location 'to' -- this is kludgey,
# but file.copy does not handle copying of directories cleanly
dir_copy <- function(from, to, overwrite = TRUE, all.files = TRUE,
                     pattern = NULL, ignore.case = TRUE) {

  #owd <- getwd()
  #on.exit(setwd(owd), add = TRUE)

  # Make sure we're doing sane things
  if (!is_dir(from)) stop("'", from, "' is not a directory.")

  if (file.exists(to)) {
    if (overwrite) {
      unlink(to, recursive = TRUE)
    } else {
      stop(paste( sep = "",
                  if (is_dir(to)) "Directory" else "File",
                  " already exists at path '", to, "'."
      ))
    }
  }

  success <- dir.create(to, recursive = TRUE)
  if (!success) stop("Couldn't create directory '", to, "'.")

  # Get relative file paths
  files.relative <- list.files(from, all.files = all.files, full.names = FALSE,
                               recursive = TRUE, no.. = TRUE)

  # Apply the pattern to the files
  if (!is.null(pattern)) {
    files.relative <- Reduce(intersect, lapply(pattern, function(p) {
      grep(
        pattern = p,
        x = files.relative,
        ignore.case = ignore.case,
        perl = TRUE,
        value = TRUE
      )
    }))
  }

  # Get paths from and to
  files.from <- file.path(from, files.relative)
  files.to <- file.path(to, files.relative)

  # Create the directory structure
  dirnames <- unique(dirname(files.to))
  sapply(dirnames, function(x) dir.create(x, recursive = TRUE, showWarnings = FALSE))

  # Copy the files
  res <- file.copy(files.from, files.to)
  if (!all(res)) {
    # The copy failed; we should clean up after ourselves and return an error
    unlink(to, recursive = TRUE)
    stop("Could not copy all files from directory '", from, "' to directory '", to, "'.")
  }
  stats::setNames(res, files.relative)

}
