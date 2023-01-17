
sign_in_errors <- c(
  "email is not authorized to access this app",
  "Invalid password"
)

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
auth_filter <- function(method = c("basic", "cookie")) {

  method <- sort(method)
  if (identical(length(method), 1L)) {
    if (!(method %in% c("basic", "cookie"))) {
      stop("invalid `method` argument", call. = FALSE)
    }
  } else {
    if (!identical(method, c("basic", "cookie"))) {
      stop("invalid `method` argument", call. = FALSE)
    }
  }

  function(req, res) {

    err_msg <- NULL
    req$polished_session <- NULL

    # attempt to find session based on cookie

    polished_cookie <- req$cookies$polished
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

          if (err_msg %in% sign_in_errors) {
            res$status <- 400L
          } else {
            res$status <- 500L
          }
        }

        err_msg <<- err$message

        invisible(NULL)
      })

      if (is.null(err_msg)) {
        plumber::forward()
      } else {

        if (!("basic" %in% method)) {
          return(list(
            error = jsonlite::unbox(err_msg)
          ))
        } else {
          # set err_msg back to NULL and check basic auth
          err_msg <- NULL
        }
      }
    }

    # check basic auth and attempt to sign in
    auth_header <- req[["HTTP_AUTHORIZATION"]]

    if ("basic" %in% method) {

      if (is.null(auth_header)) {
        if (identical(length(method), 1L)) {
          res$status <- 401L # unauthorized
          return(list(
            error = jsonlite::unbox("API key not provided in HTTP_AUTHORIZATION header")
          ))
        }

      } else {

        tryCatch({

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

          sc <- status_code(r$response)
          if (!identical(sc, 200L)) {
            res$status <- sc
            stop(r$content$error, call. = FALSE)
          }
          rc <- r$content

          hold_session <- get_sessions(
            app_uid = .polished$app_uid,
            hashed_cookie = rc$hashed_cookie
          )

          sc2 <- httr::status_code(hold_session$response)
          if (!identical(sc, 200L)) {
            res$status <- sc
            stop(hold_session$content$error, call. = FALSE)
          } else {
            req$polished_session <- hold_session$content
          }

        }, error = function(err) {

          print("basic auth error")
          err_msg <<- conditionMessage(err)
          if (identical(res$status, 200L)) {
            if (err_msg %in% sign_in_errors) {
              res$status <- 400L
            } else {
              res$status <- 500L
            }

          }


          invisible(NULL)
        })

        if (!is.null(err_msg)) {
          return(list(
            error = jsonlite::unbox(err_msg)
          ))
        } else {
          return(list(
            plumber::forward()
          ))
        }
      }
    }


  }
}
