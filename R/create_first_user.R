#' create the first user of the Shiny app
#'
#' Used to create the document that contains the first user of the Shiny app so that
#' the developer adding Polished to the Shiny app will be able to sign in without having
#' to manually create the user document in the Firestore web UI.
#'
#' @param firebase_functions_url string - the Firebase functions url
#' @param email the first users email address
#' @param app_name string - the name of the app to add the user to
#' @param is_admin boolean - TRUE by default
#' @param invite_status string - "pending" by default
#' @param time_created POSIXct datetime - current time UTC by default
#'
#' @importFrom lubridate with_tz
#'
create_first_user <- function(
  firebase_functions_url,
  email,
  app_name,
  is_admin = TRUE,
  invite_status = "pending",
  time_created = lubridate::with_tz(Sys.time(), tzone = "UTC")) {

  # TODO: how can we securly do this??
  #url_out <- paste0(firebase_functions_url, "createUser")
  #r <- httr::GET(
  #  url_out,
  #  query = list(
  #    app_name = self$app_name,
  #    role = role
  #  )
  #)
  #httr::stop_for_status(r)
  #role_delete_text <- httr::content(r, "text")
  #role_delete_text <- jsonlite::fromJSON(role_delete_text)

}