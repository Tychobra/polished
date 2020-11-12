#' Add Sentry to the UI of a Shiny app
#'
#' @param sentry_dsn the Sentry DSN of your Sentry project
#' @param app_name the uid for the app
#' @param user the polished user
#' @param r_env the active R config env. Defaults to "default".
#'
#' @importFrom htmltools tagList tags
#'
#' @noRd
#'
sentry_ui <- function(sentry_dsn, app_uid, user = NULL, r_env = "default") {


  user_json <- jsonlite::toJSON(user, auto_unbox = TRUE)

  htmltools::tagList(
    tags$script(
      src = "https://browser.sentry-cdn.com/5.27.3/bundle.tracing.min.js",
      integrity = "sha384-L3tHj4nHK/1p8GjYGsCd8gVcdnsl8Gx4GbI0xwa76GI9O5Igwsd9RxET9DJRVAhP",
      crossorigin = "anonymous"
    ),
    tags$script(src="polish/js/sentry.js"),
    tags$script(
      sprintf(
        "sentry_init('%s', '%s', %s, '%s')",
        sentry_dsn,
        app_uid,
        user_json,
        r_env
      )
    )
  )
}
