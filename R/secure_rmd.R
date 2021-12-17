


flex_sign_out <- function() {
  shiny::actionLink(
    "sign_out",
    "Sign Out",
    icon = shiny::icon("sign-out-alt"),
    style = "
      font-family: 'Source Sans Pro',Calibri,Candara,Arial,sans-serif;
      position: absolute;
      top: 0;
      right: 15px;
      color: #FFFFFF;
      z-index: 9999;
      padding: 15px;
      text-decoration: none;"
  )
}

pdf_sign_out <- function() {
  shiny::actionButton(
    "sign_out",
    "Sign Out",
    icon = shiny::icon("sign-out-alt"),
    style = "
      font-family: 'Source Sans Pro',Calibri,Candara,Arial,sans-serif;
      position: absolute;
      top: 56px;
      right: 15px;;
      z-index: 9999;
      padding: 15px;
    "
  )
}

html_sign_out <- function() {
  shiny::actionButton(
    "sign_out",
    "Sign Out",
    icon = shiny::icon("sign-out-alt"),
    style = "
      font-family: 'Source Sans Pro',Calibri,Candara,Arial,sans-serif;
      position: absolute;
      top: 0;
      right: 15px;
      z-index: 9999;
      padding: 15px;
    "
  )
}

overwrite_args <- function(x, y, xname) {
  x <- x[
    !sapply(x, is.null)
  ]
  y <- y[
    !sapply(x, is.null)
  ]
  inames <- intersect(names(x),
                      names(y))
  if (length(inames) > 0) {
    warning(
      paste0(
        paste0(inames, collapse = ", "),
        " specified in ",
        xname, " and YAML polished header,",
        " using ", xname
      )
    )
    y <- y[
      !names(y) %in% inames
    ]
  }
  x <- as.list(x)
  y <- as.list(y)
  x <- modifyList(
    y,
    x
  )
  x
}




#' Render and secure Rmarkdown document
#'
#' \code{secure_rmd()} can be used to render (or run) and secure many
#' types of Rmarkdown documents. Rendering is handled either by \code{rmarkdown::render}
#' or, if using \code{shiny}, a \code{shiny} app is constructed, and the then
#' the output is secured with \code{polished} authentication.
#'
#' @param rmd_file_path the path the to .Rmd file.
#' @param global_sessions_config_args arguments to be passed to \code{\link{global_sessions_config}}.
#' @param sign_in_page_args a named \code{list()} to customize the Sign In page
#' UI. Valid names are `color`, `company_name`, `logo`, & `background_image`.
#' (**NOTE:** YAML header values override these values if both provided).
#' @param sign_out_button A \code{shiny::actionButton} or \code{shiny::actionLink} with \code{inputId = "sign_out"}.
#' If this argument is left as \code{NULL}, \code{secure_rmd} will attempt to add in an appropriate sign
#' out button/link depending on the output format of your .Rmd document.  Set this argument to \code{list()}
#' to not include a sign out button.
#'
#' @export
#'
#' @return a Shiny app object
#'
#' @importFrom shiny shinyApp actionButton actionLink addResourcePath icon observeEvent onStop
#' @importFrom htmltools tags tagList includeHTML
#' @importFrom rmarkdown render
#' @importFrom utils modifyList
#'
#'
#' @examples
#'
#' \dontrun{
#'
#' secure_rmd(system.file("examples/rmds/flexdashboard.Rmd", package = "polished"))
#' secure_rmd(system.file("examples/rmds/flexdashboard.Rmd", package = "polished"),
#' global_sessions_config_args = list(app_name = "different_name")
#' )
#' secure_rmd(system.file("examples/rmds/flexdashboard_shiny.Rmd", package = "polished"))
#' secure_rmd(system.file("examples/rmds/html_document.Rmd", package = "polished"))
#' secure_rmd(system.file("examples/rmds/pdf_document.Rmd", package = "polished"))
#' io_file_path <- system.file(
#'   "examples/rmds/ioslides/ioslides_presentation.Rmd",
#'   package = "polished"
#' )
#' secure_rmd(io_file_path)
#' }
secure_rmd <- function(
  rmd_file_path,
  global_sessions_config_args = list(),
  sign_in_page_args = list(),
  sign_out_button = NULL
) {

  yaml_header <- yamlFromRmd(rmd_file_path)

  yaml_polished <- yaml_header$polished
  yaml_polished_global_config <- yaml_polished$global_sessions_config

  # global_sessions_config_args overrides
  # global_sessions_config_args
  # remove any NULL
  global_sessions_config_args <-
    overwrite_args(global_sessions_config_args,
                   yaml_polished_global_config,
                   xname = "global_sessions_config_args")


  if (is.null(global_sessions_config_args$api_key)) {
    global_sessions_config_args$api_key <- get_api_key()
  }

  # Minimum args needed for an app
  if (is.null(global_sessions_config_args$app_name)) {
    stop('polished "app_name" must be provided', call. = FALSE)
  }
  if (is.null(global_sessions_config_args$api_key)) {
    stop('polished "api_key" must be provided', call. = FALSE)
  }

  # check that no invalid values passed in via global_sessions_config YAML values
  if (!all(names(global_sessions_config_args) %in% c(
    "app_name",
    "api_key",
    "firebase_config",
    "admin_mode",
    "is_invite_required",
    "sign_in_providers",
    "is_email_verification_required",
    "is_auth_required",
    "sentry_dsn",
    "cookie_expires"
  ))) {
    stop("Invalid value passed to polished global_session", call. = FALSE)
  }

  do.call(
    global_sessions_config,
    global_sessions_config_args
  )


  hold_sign_in_page <- yaml_polished$sign_in_page

  if (!is.null(hold_sign_in_page)) {
    # check that sign in page args only contain the 4 valid values
    if (!all(names(hold_sign_in_page) %in% c("color", "company_name", "logo", "background_image"))) {
      stop("Invalid value passed to polished `sign_in_page` in YAML header.", call. = FALSE)
    }

    hold_sign_in_page <- as.list(hold_sign_in_page)
    sign_in_page_args <- as.list(sign_in_page_args)

    if (!is.null(hold_sign_in_page$logo)) {
      sign_in_page_args$logo_top <- tags$img(
        src = hold_sign_in_page$logo,
        alt = "Logo",
        style = "width: 125px; margin-top: 30px; margin-bottom: 30px;"
      )
      sign_in_page_args$icon_href <- hold_sign_in_page$logo

      # remove the logo from the sign in page value passed from the YAML header
      hold_sign_in_page$logo <- NULL
    }

    sign_in_page_args <-
      overwrite_args(sign_in_page_args,
                     hold_sign_in_page,
                     xname = "sign_in_page_args")

  }

  if (is.null(sign_out_button)) {

    # use the output format to choose a default sign out button
    if (!is.null(names(yaml_header$output)[1])) {
      output_format <- names(yaml_header$output)[1]
    } else {
      output_format <- yaml_header$output[1]
    }

    # remove package prefix from output format
    output_format <- gsub("^.*::", "", output_format)

    # set the default sign out button
    if (identical(output_format, "flex_dashboard")) {
      sign_out_button <- flex_sign_out()
    } else if (identical(output_format, "pdf_document")) {
      sign_out_button <- pdf_sign_out()
    } else {
      sign_out_button <- html_sign_out()
    }
  }


  if (!is.null(yaml_header$runtime) &&
      yaml_header$runtime %in% c("shiny", "shinyrmd", "shiny_prerendered")) {
    # runtime = shiny

    rmd_file_name <- basename(rmd_file_path)

    dir <- dirname(rmd_file_path)
    # form and test locations
    dir <- normalizePath(dir)
    if (!dir.exists(dir)) {
      stop(paste0("The directory '", dir, "' does not exist"), call. = FALSE)
    }

    # add rmd_resources handler on start
    on_start <- function() {
      global_r <- file.path(dir, "global.R")
      if (file.exists(global_r)) {
        source(global_r, local = FALSE)
      }
      shiny::addResourcePath("rmd_resources", system.file("rmd/h/rmarkdown", package = "rmarkdown"))
    }

    # use rmarkdown internal functions to generate the shiny ui and server
    ui_rmd <- rmarkdown:::rmarkdown_shiny_ui(dir, rmd_file_name)

    server_rmd <- rmarkdown:::rmarkdown_shiny_server(
      dir,
      rmd_file_name,
      auto_reload = FALSE,
      render_args = list(
        envir = parent.frame()
      )
    )


    ui <- function(req) {
      tagList(
        sign_out_button,
        ui_rmd(req)
      )
    }



    server_out <- secure_server(function(input, output, session) {

      shiny::observeEvent(input$sign_out, {

        tryCatch({
          sign_out_from_shiny(session)
          session$reload()
        }, error = function(err) {
          print(err)
        })

      })

      server_rmd(input, output, session)

    })

  } else {
    # static (non shiny) document (html or pdf)

    static_file_path <- rmarkdown::render(rmd_file_path)

    static_file_name <- basename(static_file_path)
    static_file_dir <- dirname(static_file_path)
    shiny::addResourcePath("polished_static", static_file_dir)

    on_start <- function() {
      global_r <- file.path(static_file_dir, "global.R")
      if (file.exists(global_r)) {
        source(global_r, local = FALSE)
      }
    }

    embeded_app <- tags$iframe(
      src = file.path("polished_static", static_file_name),
      height = "100%",
      width = "100%",
      style = "height: 100%; width: 100%; overflow: hidden; position: absolute; top:0; left: 0; right: 0; bottom:0",
      frameborder = "0"
    )

    ui <- htmltools::tagList(
      tags$head(
        tags$style("
          body {
            margin: 0;
            padding: 0;
            overflow: hidden
          }
        ")
      ),
      sign_out_button,
      embeded_app
    )

    server_out <- secure_server(function(input, output, session) {

      shiny::observeEvent(input$sign_out, {

        tryCatch({
          sign_out_from_shiny(session)
          session$reload()
        }, error = function(err) {
          print(err)
        })

      })

    })
  }


  secure_ui_args <- list(
    ui = ui,
    custom_admin_button_ui = shiny::actionButton(
      "polished-go_to_admin_panel",
      "Admin Panel",
      icon = shiny::icon("cog"),
      class = "btn-primary btn-lg",
      style = "position: fixed; bottom: 15px; right: 15px; color: #FFFFFF; z-index: 9999; background-color: #0000FF; padding: 15px;"
    )
  )

  if (length(sign_in_page_args) > 0) {
    secure_ui_args$sign_in_page_ui <- do.call(sign_in_ui_default, sign_in_page_args)
  }

  ui_out <- do.call(secure_ui, secure_ui_args)


  shiny::shinyApp(ui_out, server_out, onStart = on_start)
}

#' copied internal function from rsconnect package
#' https://github.com/rstudio/rsconnect/blob/250aa5c0c5071c1ae3f7ecc407164da5801bc17e/R/bundle.R#L496
#'
#' @importFrom yaml yaml.load
#'
#' @noRd
#'
yamlFromRmd <- function(filename) {
  lines <- readLines(filename, warn = FALSE, encoding = "UTF-8")
  delim <- grep("^(---|\\.\\.\\.)\\s*$", lines)
  if (length(delim) >= 2) {
    if (delim[[1]] == 1 || all(grepl("^\\s*$", lines[1:delim[[1]]]))) {
      if (grepl("^---\\s*$", lines[delim[[1]]])) {
        if (diff(delim[1:2]) > 1) {
          yamlData <- paste(lines[(delim[[1]] + 1):(delim[[2]] -
                                                      1)], collapse = "\n")
          return(yaml::yaml.load(yamlData))
        }
      }
    }
  }
  return(NULL)
}
