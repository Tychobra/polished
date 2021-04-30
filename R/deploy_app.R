
valid_gcp_regions <- c(
  "asia-east1",
  "asia-east2",
  "asia-northeast1",
  "asia-northeast2",
  "asia-northeast3",
  "asia-south1",
  "asia-southeast1",
  "asia-southeast2",
  "australia-southeast1",
  "europe-north1",
  "europe-west1",
  "europe-west2",
  "europe-west3",
  "europe-west4",
  "europe-west6",
  "northamerica-northeast1",
  "southamerica-east1",
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
#' @param api_url The Polished API url.  Defaults to "https://host-api.polished.tech".  You should
#' not change from the default unless you are testing a development version of the API.
#' @param launch_browser Whether or not to open your default browser to your newly deployed app
#' after it is successfully deployed.  \code{TRUE} by default.
#' @param region the region to deploy the app to on Google Cloud Platform.  See
#' \url{https://cloud.google.com/compute/docs/regions-zones} for all available regions
#' on Google Cloud Platform.  Currently on "us-east1" is supported, but soon, all regions
#' will be supported.
#' @param ram_gb the amount of memory to allocate to your Shiny app server. Valid values are
#' 2, 4, or 8.
#' @param r_ver Character string of R version.  If kept as \code{NULL}, the default, then
#' \code{deploy_app()} will detect the R version you are currently running.  The R version must be a version
#' supported by an r-ver Docker image.  You can see all the r-ver Docker image versions
#' of R here \url{https://github.com/rocker-org/rocker-versioned2/tree/master/dockerfiles} and here
#' \code{https://github.com/rocker-org/rocker-versioned/tree/master/r-ver}.
#' @param tlmgr a character vector of TeX Live packages to install.  This is only used if your Shiny
#' app generates pdf documents.  Defaults to \code{character(0)} for no TeX Live installation.  Set to
#' \code{TRUE} for a minimal TeX Live installation, and pass a character vector of your TeX Live package
#' dependencies to have all your TeX Live packages installed at build time.
#'
#' @importFrom utils browseURL
#' @importFrom httr POST authenticate config status_code content upload_file
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
  api_url = "https://host-api.polished.tech",
  launch_browser = TRUE,
  region = "us-east1",
  ram_gb = 2,
  r_ver = NULL,
  tlmgr = character(0)
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
  if (!("app.r" %in% file_names || ("ui.r" %in% file_names && "server.r" %in% file_names))) {
    stop('"app_dir" must contain a file named "app.R" or files named "ui.R" and "server.R"', call. = FALSE)
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
  cat("Your Shiny app will open in your default web browser once deployment is complete.\n")
  cat("Deployment status can be found at https://dashboard.polished.tech")
  zip_to_send <- httr::upload_file(
    path = app_zip_path,
    type = "application/x-gzip"
  )

  url_ <- paste0(api_url, "/deploy-app")
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
      tlmgr = paste(tlmgr, collapse = ",")
    ),
    encode = "multipart",
    http_version = 0,
    # timeout after 30 minutes
    timeout = 1800
  )

  res_content <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  hold_status <- httr::status_code(res)
  if (identical(hold_status, 200L)) {
    cat(" Done\n")

    if (isTRUE(launch_browser)) {
      # launch user's browser with newly deployed Shiny app
      utils::browseURL(res_content$url)
    }
  }

  list(
    status = hold_status,
    content = res_content
  )
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
bundle_app <- function (
  app_dir = "."
) {


  deps_list <- get_package_deps(app_dir)

  # create yaml file with all the dependencies
  yml_path <- file.path(app_dir, "deps.yaml")
  yaml::write_yaml(deps_list, yml_path)


  tar_name <- "shiny_app.tar.gz"

  bundles_dir <- tempdir()

  file <- file.path(bundles_dir, tar_name)

  current_wd <- getwd()
  setwd(app_dir)
  on.exit({setwd(current_wd)}, add = TRUE)
  result <- utils::tar(
    tarfile = file,
    compression = "gzip",
    tar = "internal"
  )

  if (result != 0) {
    stop("Failed to bundle the Shiny app.")
  }

  file
}

