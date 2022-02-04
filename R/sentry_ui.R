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

  function(page) {
    htmltools::tagList(
      shiny::includeScript(
        path = "https://browser.sentry-cdn.com/6.17.4/bundle.tracing.min.js",
        integrity = "sha384-eIliztiJMgTUGzEQjjcCty1MN9hIqsz8GtzP/UTAHo6yxQgA6ZogOH2YNSlJRYWO",
        type = "text/javascript",
        crossorigin = "anonymous"
      ),
      tags$script(src = "polish/js/sentry.js"),
      tags$script(
        sprintf(
          "sentry_init('%s', '%s', %s, '%s', '%s')",
          sentry_dsn,
          app_uid,
          user_json,
          r_env,
          page
        )
      )
    )
  }

}
