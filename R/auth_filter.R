


#' Auth filter for a Plumber API
#'
#' @param req the request
#' @param res the response
#'
#' @export
#'
auth_filter <- function(req, res) {


  err_msg <- NULL
  req$polished_session <- NULL
  tryCatch({

    # attempt to find session based on cookie
    polished_cookie <- req$cookies$polished

    if (is.null(polished_cookie)) {
      res$status <- 401L # unauthorized
      stop("polished cookie not provided", call. = FALSE)
    }

    # hash the cookie if sent unhashed
    if (grepl("p0.", polished_cookie, fixed = TRUE)) {
      polished_cookie <- digest::digest(polished_cookie)
    }

    hold_session <- get_sessions(
      app_uid = .polished$app_uid,
      hashed_cookie = polished_cookie
    )

    sc <- status_code(hold_session$response)
    if (!identical(sc, 200L)) {
      res$status_code <- sc
      stop(sc$content$error, call. = FALSE)
    }

    if (is.null(hold_session$content)) {
      res$status <- 401L
      stop("session not found", call. = FALSE)
    }

    req$polished_session <- hold_session$content

  }, error = function(err) {
    print(err)

    if (res$status == 200L) {
      res$status <- 500L
    }

    err_msg <<- err$message
  })

  if (!is.null(err_msg)) {
    return(list(
      error = jsonlite::unbox(err_msg)
    ))
  } else {
    plumber::forward()
  }
}
