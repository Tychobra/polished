
#' Valid Regions for Polished Hosting
#'
#' Set the `region` argument of `deploy_app()` to one of these regions.
#'
#' @export
#'
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
  "europe-central2",
  "europe-north1",
  "europe-southwest1",
  "europe-west1",
  "europe-west2",
  "europe-west3",
  "europe-west4",
  "europe-west6",
  "europe-west8",
  "europe-west9",
  "me-west1",
  "northamerica-northeast1",
  "northamerica-northeast2",
  "southamerica-east1",
  "southamerica-west1",
  "us-central1",
  "us-east1",
  "us-east4",
  "us-east5",
  "us-south1",
  "us-west1",
  "us-west2",
  "us-west3",
  "us-west4"
)

#' Deploy a Shiny app to Polished Hosting
#'
#' @param app_name Your Shiny app's name.
#' @param app_dir The path to the directory containing your Shiny app.
#' @param api_key Your `polished` API key. Defaults to \code{Sys.getenv("POLISHED_API_KEY")} if set.
#' @param launch_browser Boolean (default: \code{TRUE}) - Whether or not to open
#' your newly deployed app in your default web browser after successful deployment.
#' @param region the region to deploy the app to on Google Cloud Platform. See
#' \url{https://cloud.google.com/run/docs/locations} for all available regions
#' on Google Cloud Platform. Currently, database connections are only supported for
#' `us-east1`. See \url{https://polished.tech/docs/06-database-connections} for details.
#' @param ram_gb the amount of memory (in `GiB`) to allocate to your Shiny app's server.
#' Valid values are `2`, `4`, `8`, `16`, or `32`.
#' @param r_ver Character string of desired `R` version.  If kept as \code{NULL} (the default),
#' \code{deploy_app()} will detect the R version you are currently running.  The R version must be a version
#' supported by an `r-ver` Docker image.  You can see all the `r-ver` Docker image versions
#' of R here \url{https://github.com/rocker-org/rocker-versioned2/tree/master/dockerfiles} and here
#' \url{https://github.com/rocker-org/rocker-versioned/tree/master/r-ver}.
#' @param tlmgr a character vector of `TeX Live` packages to install.  This is only used if your Shiny
#' app generates `PDF` documents.  Defaults to \code{character(0)} for no `TeX Live` installation. Provide a
#' character vector of your TeX Live package dependencies to have all your TeX Live packages installed at build time.
#' @param golem_package_name if your Shiny app was created as a package with the
#' `golem` package, provide the name of the Shiny app package as a character string.
#' Defaults to \code{NULL}.  Keep as \code{NULL} for non `golem` Shiny apps.
#' @param cache Boolean (default: \code{TRUE}) - whether or not to cache the Docker image.
#' @param gh_pat optional GitHub PAT for installing packages from private GitHub repos.
#' @param max_sessions the maximum number of concurrent sessions to run on a single app instance before
#' starting another instance.  e.g. set to 5 to have a max of 5 user sessions per app instance.
#' The default is \code{Inf} which will run all concurrent sessions on only 1 app instance.
#'
#'
#' @importFrom utils browseURL
#' @importFrom httr POST authenticate handle_reset status_code content upload_file
#' @importFrom jsonlite fromJSON write_json
#'
#' @export
#'
#' @return an object of class \code{polished_api_res}.
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
  api_key = get_api_key(),
  launch_browser = TRUE,
  region = "us-east1",
  ram_gb = 2,
  r_ver = NULL,
  tlmgr = character(0),
  golem_package_name = NULL,
  cache = TRUE,
  gh_pat = NULL,
  max_sessions = Inf
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

  if (!(ram_gb %in% c(2, 4, 8, 16, 32))) {
    stop("`ram_gb` must be 2, 4, 8, 16, 32", call. = FALSE)
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

  deps_list <- get_package_deps(app_dir, all_deps = FALSE)

  # create yaml file with all the dependencies
  deps_path <- file.path(app_dir, "deps.json")
  jsonlite::write_json(
    deps_list,
    path = deps_path,
    auto_unbox = TRUE,
    pretty = TRUE
  )

  params <- list(
    app_name = app_name,
    region = region,
    ram_gb = ram_gb,
    r_ver = r_ver,
    tlmgr = tlmgr,
    golem_package_name = golem_package_name,
    cache = cache,
    gh_pat = gh_pat,
    max_sessions = max_sessions
  )
  jsonlite::write_json(
    params,
    path = file.path(app_dir, "params.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  app_zip_path <- bundle_app(app_dir = app_dir)
  cat(" Done\n")

  cat("Deploying App.  Hang tight.  This may take a while...\n")
  if (isTRUE(launch_browser)) {
    cat("Your Shiny app will open in your default web browser once deployment is complete.\n")
  }

  # Check if zipped app is larger than Cloud Run's max request size (32 Mb)
  if (as.numeric(file.size(app_zip_path)) > 33554432) {
    stop("Zipped application is too large (> 32 Mb)", call. = FALSE)
  }

  zip_to_send <- httr::upload_file(
    path = app_zip_path,
    type = "application/x-gzip"
  )


  cat("Deployment status can be found at https://dashboard.polished.tech\n")

  url_ <- paste0(.polished$host_api_url, "/hosted-apps")
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
    encode = "multipart",
    #http_version = 0,
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
#' @return the file path of the app bundle
#'
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
    message("Could not copy these files from directory '", from, "' to directory '", to, "':")
    message( paste( files.from[ res==FALSE ], collate="\n" ) )
    stop( "Cannot continue." )
  }
  stats::setNames(res, files.relative)

}
