

#' html for iframe for hosting the Shiny app
#'
#' @param app_name the name of a single Shiny app
#' @param title Defaults to `NULL`.  The window title to display in the Browser tab. If
#' left as `NULL`, the broser tab title will be the title case version of `app_name`
#'
#' @export
#'
#' @examples
#'
#' write_firebase_hosting_html("shiny_app_1")
#'
generate_firebase_hosting_html <- function(app_name, title = NULL) {

  # use title case version of `app_name` for title if title is NULL
  if (is.null(title)) {
    title <- gsub("_", " ", app_name, fixed = TRUE)
    title <- tools::toTitleCase(title)
  }

  c(
    '<!DOCTYPE html>',
    '<html lang="en">',
    '  <head>',
    '    <meta charset="UTF-8">',
    '    <meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '    <meta http-equiv="X-UA-Compatible" content="ie=edge">',
    '    <title>', title, '</title>',
    '  </head>',
    '  <body style="margin:0px; padding:0px; overflow:hidden">',
    '    <iframe ',
    paste0('src="https://tychobra.shinyapps.io/', app_name, '" '),
    '       width="100%" ',
    '       height="100%" ',
    '       style="height: 100%; overflow: hidden; position: fixed; width:100%;"',
    '       frameBorder=0 title="Shiny App">',
    '    </iframe>',
    '  </body>',
    '</html>'
  )
}

#' write hosting html to a file
#'
#' @param app_name the name of the app
#'
#' @export
#'
#' @examples
#'
#' write_firebase_hosting_html_single_app("shiny_app_1")
#'
write_firebase_hosting_html_single_app <- function(app_name) {

  html_text <- generate_firebase_hosting_html(app_name)

  hosting_dir_exists <- dir.exists("hosting")

  if (isFALSE(hosting_dir_exists)) {
    dir.create("hosting")
  }

  # create the dir to hold each html
  dir.create(file.path("hosting", app_name))

  file_path <- file.path("hosting", app_name, "index.html")
  file.create(file_path)

  file_conn <- file(file_path)
  on.exit(close(file_conn), add = TRUE)

  writeLines(
    html_text,
    file_conn,
  )
}

#' write firebase hosting html
#'
#' write firebase hosting html for one or more apps
#'
#' @param app_names the names of the apps
#'
#' @export
#'
#' @examples
#'
#' write_firebase_hosting_html("shiny_app_1")
#'
#' write_firebase_hosting_html(c("shiny_app_1", "shiny_app_2"))
#'
write_firebase_hosting_html <- function(app_names) {
  lapply(app_names, write_firebase_hosting_html_single_app)
}
