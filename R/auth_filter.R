


#' Auth filter for a Plumber API
#'
#' @param req the request
#' @param res the response
#' @param method The authentication method.  Valid options are "cookie" and/or "basic".  If
#' "cookie", the filter will authenticate the request using the cookie.  If
#' "basic" is set, the filter will authenticate the request using basic auth.  If both
#' "cookie" and "basic" are set, then the filter will first attempt to authenticate
#' using the cookie, and, if that fails, it will attempt to authenticate using basic
#' auth.
#'
#' @export
#'
auth_filter <- function(req, res, method = "cookie") {

  if (length(intersect(c("cookie", "basic"), method) == 0)) {
    stop("invalid `method` argument", call. = FALSE)
  }


  err_msg <- NULL
  req$polished_session <- NULL
  tryCatch({
    # attempt to find session based on cookie
    polished_cookie <- req$cookies$polished

    if ("cookie" %in% method) {

      if (is.null(polished_cookie)) {
        res$status <- 401L # unauthorized
        err_msg <- "polished cookie not provided"
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
        err_msg <- sc$content$error
      }

      if (is.null(hold_session$content)) {
        res$status <- 401L
        err_msg <- "session not found"
      }

      req$polished_session <- hold_session$content

      if (!is.null(err_msg)) {
        return(list(
          error = jsonlite::unbox(err_msg)
        ))
      } else {
        plumber::forward()
      }
    }

    if ("basic" %in% method) {
      # check basic auth and attempt to sign in
      auth_header <- req[["HTTP_AUTHORIZATION"]]
      if (is.null(auth_header)) {
        res$status <- 401L # unauthorized
        err_msg <- "API key not provided in HTTP_AUTHORIZATION header"
      }

      credentials_encoded <- strsplit(auth_header, " ")[[1]][2]
      credentials <- rawToChar(base64enc::base64decode(credentials_encoded))
      credentials <- strsplit(credentials, ":", fixed = TRUE)[[1]]

      if (is.null(polished_cookie)) {
        polished_cookie <- paste0("api-", uuid::UUIDgenerate())
      }


      hold_session <- polished:::sign_in_email(
        email = credentials[1],
        password = credentials[2],
        hashed_cookie = digest::digest(polished_cookie)
      )

      req$polished_session <- hold_session

      if (!is.null(err_msg)) {
        return(list(
          error = jsonlite::unbox(err_msg)
        ))
      } else {
        plumber::forward()
      }
    }

  }, error = function(err) {
    print(err)

    if (res$status == 200L) {
      res$status <- 500L
    }

    err_msg <<- err$message

    invisible(NULL)
  })

  return(list(
    error = jsonlite::unbox(err_msg)
  ))

}
