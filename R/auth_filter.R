


#' Auth filter for a Plumber API
#'
#' @param method The authentication method.  Valid options are "basic" and/or "cookie".  If
#' "basic" is set, the filter will authenticate the request using basic auth.  If
#' "cookie", the filter will authenticate the request using the cookie.  If both
#' "cookie" and "basic" are set, then the filter will first attempt to authenticate
#' using the cookie, and, if that fails, it will attempt to authenticate using basic
#' auth.  If you use cookie based auth, and you want to send requests directly from the browser,
#' then be sure to set your Plumber API to allow for cookies.  See
#' \url{https://polished.tech/blog/polished-plumber} for details.
#'
#' @export
#'
auth_filter <- function(method = "basic") {

  function(req, res) {

    err_msg <- NULL
    req$polished_session <- NULL

    if (length(intersect(c("cookie", "basic"), method)) == 0) {
      res$status <- 400
      return(list(
        error = jsonlite::unbox("invalid `method` argument")
      ))
    }


    # attempt to find session based on cookie
    polished_cookie <- req$cookies$polished

    if ("basic" %in% method) {

      tryCatch({

        # check basic auth and attempt to sign in
        auth_header <- req[["HTTP_AUTHORIZATION"]]
        if (is.null(auth_header)) {
          res$status <- 401L # unauthorized
          stop("API key not provided in HTTP_AUTHORIZATION header", call. = FALSE)
        }

        credentials_encoded <- strsplit(auth_header, " ")[[1]][2]
        credentials <- rawToChar(base64enc::base64decode(credentials_encoded))
        credentials <- strsplit(credentials, ":", fixed = TRUE)[[1]]

        if (is.null(polished_cookie)) {
          polished_cookie <- paste0("api-", uuid::UUIDgenerate())
        }


        r <- polished:::sign_in_email(
          email = credentials[1],
          password = credentials[2],
          hashed_cookie = digest::digest(polished_cookie)
        )

        sc <- status_code(hold_session$response)
        if (!identical(sc, 200L)) {
          res$status <- sc
          stop(r$content$error, call. = FALSE)
        } else {
          req$polished_session <- r$content
        }
      }, error = function(err) {

        print("basic auth error")
        if (identical(res$status, 200L)) {
          res$status <- 500L
        }
        err_msg <<- conditionMessage(err)

        invisible(NULL)
      }

      if (!is.null(err_msg)) {
        return(list(
          error = jsonlite::unbox(err_msg)
        ))
      } else {
        return(list(
          plumber::forward()
        ))
      })
    }



    if ("cookie" %in% method) {

      tryCatch({

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
          res$status <- sc
          stop(sc$content$error, call. = FALSE)
        } else {
          req$polished_session <- hold_session$content
        }

        if (is.null(hold_session$content)) {
          res$status <- 401L
          stop("session not found", call. = FALSE)
        }

      }, error = function(err) {
        print(err)

        if (res$status == 200L) {
          res$status <- 500L
        }

        err_msg <<- err$message

        invisible(NULL)
      })

      if (!is.null(err_msg)) {
        return(list(
          error = jsonlite::unbox(err_msg)
        ))
      } else {
        plumber::forward()
      }
    }
  }
}
