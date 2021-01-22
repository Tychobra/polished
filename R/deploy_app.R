#' Deploy a Shiny app to Polished Hosting
#'
#' @param app_name You Shiny app's name.
#' @param app_dir The path to the directory containing your Shiny app.
#' @param api_key Your polished.tech API key.  Defaults to \code{getOption("polished")$api_key}.
#' @param api_url The Polished API url.  Defaults to "https://host.polished.tech".  This is used
#' for testing during polished API development.  You probably should not change this url from
#' the default.
#' @param launch_browser Whether or not to open your default brower to your newly deployed app
#' after it is successfully deployed.  \code{TRUE} by default.
#' @param region the region to deploy the app to on Google Cloud Platform.  See
#' \url{https://cloud.google.com/compute/docs/regions-zones} for all available regions
#' on Google Cloud Platform.  Currenlty on "us-east1" is supported, but soon, all reagions
#' will be supported.
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
  api_url = "https://host.polished.tech",
  launch_browser = TRUE,
  region = "us-east1"
) {

  if (!identical(region, "us-east1")) {
    stop('only region "us-east1" is supported at this time', call. = FALSE)
  }


  cat("Creating app bundle...")
  app_zip_path <- bundle_app(
    app_dir = app_dir
  )
  cat(" Done\n")

  cat("Deploying App.  This may take a while...")
  zip_to_send <- httr::upload_file(
    path = app_zip_path,
    type = "application/x-gzip"
  )

  res <- httr::POST(
    url = paste0(api_url, "/deploy-app"),
    httr::authenticate(
      user = api_key,
      password = ""
    ),
    body = list(
      app_zip = zip_to_send
    ),
    query = list(
      app_name = app_name,
      region = region
    ),
    encode = "multipart",
    httr::config(http_version = 0)
  )

  res_content <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  hold_status <- httr::status_code(res)
  if (!identical(hold_status, 200L)) {

    if (!identical(hold_status, 400L)) {
      stop(res_content$message, call. = FALSE)
    } else {
      print(res_content)
      stop("Failed to upload the Shiny app to Polished Hosting.", call. = FALSE)
    }
  }
  cat(" Done\n")


  if (isTRUE(launch_browser)) {
    # launch user's browser with newly deployed Shiny app
    utils::browseURL(res_content$url)
  }

  res_content
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

