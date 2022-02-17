#' Sign Out from your Shiny app
#'
#' Call this function to sign a user out of your Shiny app.  This function should
#' be called inside the server function of your Shiny app.  See
#' \url{https://github.com/Tychobra/polished/blob/master/inst/examples/polished_example_01/server.R}
#' For an example of this function being called after the user clicks a "Sign Out"
#' button.
#'
#' @param session the Shiny \code{session}
#' @param redirect_page the query string for the page that the user should be redirected
#' to after signing out.
#'
#' @export
#'
#' @importFrom shiny updateQueryString getDefaultReactiveDomain
#'
#'
#'
sign_out_from_shiny <- function(
  session = shiny::getDefaultReactiveDomain(),
  redirect_page = "?page=sign_in"
) {

  # using isolate() allows this function to be called in onStop()
  user <- isolate(session$userData$user())

  if (is.null(user)) stop("session$userData$user() does not exist", call. = FALSE)

  # sign the user out of polished
  .polished$sign_out(user$hashed_cookie)

  # set query string to sign in page
  shiny::updateQueryString(
    queryString = redirect_page,
    session = session,
    mode = "replace"
  )

}



