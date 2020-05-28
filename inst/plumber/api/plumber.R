library(polished)
library(dplyr)

env <- Sys.getenv("ENV")

setwd("/plumber")

if (env != "") {
  # API is running on Cloud Run.  Environment variable "ENV" is defined on GCP
  # in Cloud Run.
  Sys.setenv("R_CONFIG_ACTIVE" = env)
}

schema <- "polished"
verbose <- TRUE
# source in the database connection `conn` object
source("conn.R")
conn <- create_conn()
source("count_n_users.R")
source("get_user_by_email.R")
source("get_invite.R")
source("add_user.R")

# API requests from polished hosted come with this secret key
polished_hosted_secret <- config::get()$polished_hosted_secret

# the user limit for the free plan
free_plan_user_limit <- 10


log_file <- config::get()$log_file

# write the logs to the specified log file or standard out
if (!identical(log_file, "stdout")) {

  if (!is.character(log_file) && length(log_file) == 1) {
    stop("invalid `log_file`")
  }

  sink(log_file, append = TRUE)
}


#' write_log
#'
#' @param req the API request
#' @param type the log type.  Valid values are "request", "info", and "error"
#' @param message a custom message to include with the log
#'
#' @return JSON formatted character string of the log message
#'
write_log <- function(req, type = "request", message = "") {


  log_msg <- jsonlite::toJSON(
    list(
      request_method = req$REQUEST_METHOD,
      path_info      = req$PATH_INFO,
      account_uid    = req$account_uid,
      user_uid       = req$user_uid,
      app_uid        = req$app_uid,
      type           = type,
      message        = message
    )
  )


  cat(
    log_msg,
    "\n"
  )
}

#' check db connection
#'
#' Check that the `conn` object still has an open database connection.  If the
#' connection is not valid, attempt to reconnect.  If reconnection it successful,
#' forward the request.  If it is unsuccessful, send and error response.
#'
#' @filter check_connection
#'
function(req, res, user_uid = NULL, app_uid = NULL) {

  if (isTRUE(DBI::dbIsValid(conn))) {
    plumber::forward()
  } else {
    # attempt to reconnect to the db
    conn <<- create_conn()

    if (isTRUE(DBI::dbIsValid(conn))) {
      print("successfully reconnection")
      plumber::forward()
    } else {
      write_log(req, type = "error", message = "database connection error")
      res$status <- 500 # Unauthorized
      return(list(
        error = "Database Connection Error"
      ))
    }
  }
}


#' auth middleware
#'
#' check the authentication of each incoming request
#'
#' @filter auth
#'
function(req, res, account_uid = NULL, user_uid = NULL, app_uid = NULL) {

  auth_header <- req[["HTTP_AUTHORIZATION"]]
  req$account_uid <- NULL

  # attach user_uid and app_uid to the request so that they can always be logged later
  req$user_uid <- user_uid
  req$app_uid <- app_uid

  error <- NULL
  password_from_db <- NULL
  tryCatch({

    password_encoded <- strsplit(auth_header, " ")[[1]][2]
    credentials <- rawToChar(base64enc::base64decode(password_encoded))
    pw <- gsub(":", "", credentials, fixed = TRUE)

    if (identical(polished_hosted_secret, pw)) {

      if (is.null(account_uid)) {
        stop("`account_uid` cannot be `NULL`")
      }

      from_db <- list(uid = uid)

    } else {
      password_digest <- digest::digest(pw)

      # we need to
      from_db <- dbGetQuery(
        conn,
        paste0(
          "SELECT hashed_polished_key, uid FROM ",
          schema, ".accounts WHERE hashed_polished_key=$1"
        ),
        params = list(
          password_digest
        )
      )

      if (!identical(from_db$hashed_polished_key, password_digest)) {
        stop("keys do not match")
      }

    }



  }, error = function(err) {
    print(err)
    error <<- "there was an error"
  })


  if (is.null(error)) {
    req$account_uid <- from_db$uid
    write_log(req, user_uid, app_uid)
    plumber::forward()
  } else {
    write_log(req, user_uid, app_uid)
    res$status <- 401 # Unauthorized
    return(list(
      error = "Authentication Error"
    ))
  }

}


#' #' check stripe subscription middleware
#' #'
#' #' check if the account has an active payment method.  If the account has an
#' #' active payment method, set `is_billing_enabled` on the request to `TRUE`, otherwise else
#' #' set it to `FALSE`
#' #'
#' #' @filter stripe-check
#' #'
#' function(req, res) {
#'
#'   req$is_billing_enabled <- FALSE
#'
#'   billings_row <- DBI::dbGetQuery(
#'     conn,
#'     "SELECT created_at, payment_method_id FROM billing WHERE user_uid=$1",
#'     params = list(
#'       req$account_uid
#'     )
#'   )
#'
#'   pm_id <- billings_row$payment_method_id
#'
#'   # billing is enabled, so set it to true on the request
#'   if (length(pm_id) == 1 && !is.na(pm_id)) {
#'     req$is_billing_enabled <- TRUE
#'   }
#'
#'   # user has billing enabled
#'   plumber::forward()
#' }


##' get the app by app name
##'
##' @get /app-by-name
##'
#
# function(req, res, app_name) {
#
#   app <- DBI::dbGetQuery(
#     conn,
#     paste0("SELECT uid FROM ", schema, ".apps WHERE app_name=$1 AND account_uid=$2"),
#     params = list(
#       app_name,
#       req$account_uid
#     )
#   )
#
#   if (nrow(app) == 0) {
#     res$status <- 404
#     return(list(
#       error = "`global_sessions_config()` `app_name` not found"
#     ))
#   }
#
#   list(
#     app_uid = app$uid
#   )
# }

#' get apps
#'
#' returns a data frame of all apps for an account or, if the app_uid argument
#' is supplied, returns the row only for that specific app.
#'
#' @get /apps
#'
function(req, res, app_uid = NULL, app_name = NULL) {

  # 1 or both of app_uid and app_name must be NULL
  if (!is.null(app_uid) && !is.null(app_name)) {
    res$status <- 400 #
    return(list(
      error = "Invalid query parameters"
    ))
  }

  if (is.null(app_uid) && is.null(app_name)) {
    # return data frame of all apps
    out <- DBI::dbGetQuery(
      conn,
      paste0("SELECT * FROM ", schema, ".apps WHERE account_uid=$1"),
      params = list(
        req$account_uid
      )
    )
  } else {

    if (is.null(app_name)) {
      out <- DBI::dbGetQuery(
        conn,
        paste0("SELECT * FROM ", schema, ".apps WHERE account_uid=$1 AND app_uid=$2"),
        params = list(
          req$account_uid,
          app_uid
        )
      )
    } else {
      out <- DBI::dbGetQuery(
        conn,
        paste0("SELECT * FROM ", schema, ".apps WHERE account_uid=$1 AND app_name=$2"),
        params = list(
          req$account_uid,
          app_name
        )
      )
    }


  }

  out
}
#' create an app for a user
#'
#' @post /apps
#'
function(req, res, app_name) {

  DBI::dbExecute(
    conn,
    paste0("INSERT INTO ", schema, ".apps ( app_name, account_uid ) VALUES ( $1, $2 )"),
    params = list(
      app_name,
      req$account_uid
    )
  )

  return(list(
    status = "success"
  ))
}
#' delete an app for a user
#'
#' @delete /apps
#'
function(req, res, app_uid) {

  # When the below SQL is executed, all app_users of the app will also be deleted
  # from the app_users table in an SQL CASCADE
  DBI::dbExecute(
    conn,
    paste0("DELETE FROM ", schema, ".apps WHERE uid=$1 AND account_uid=$2"),
    params = list(
      app_uid,
      req$account_uid
    )
  )

  return(list(
    status = "success"
  ))
}

#' create a user for an account
#'
#' @post /users
#'
function(req, res, email) {

  hold_app_uid <- uuid::UUIDgenerate()

  created_by <- req$user_uid

  user_limit <- NULL
  #if (isFALSE(req$is_billing_enabled)) {
  #  user_limit <- free_plan_user_limit
  #}

  add_user(
    conn,
    email,
    created_by,
    created_by,
    schema = schema,
    unique_user_limit = user_limit
  )

  return(list(
    status = "success"
  ))
}
#' delete a user from an account
#'
#' @delete /users
#'
function(req, res, user_uid) {

  # all app_users will of the app will be deleted from the app_users table in
  # an SQL CASCADE
  DBI::dbExecute(
    conn,
    paste0("DELETE FROM ", schema, ".users WHERE uid=$1 AND account_uid=$2"),
    params = list(
      user_uid,
      req$account_uid
    )
  )

  return(list(
    status = "success"
  ))
}


#' get the app users for a specific app
#'
#'
#' @get /app-users
#'
function(req, res, app_uid) {
  #get_app_users(conn, app_uid, schema = schema)

  # find all users of the app
  app_users <- conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "app_users")) %>%
    dplyr::filter(.data$app_uid == .env$app_uid) %>%
    dplyr::select(
      .data$uid,
      .data$app_uid,
      .data$user_uid,
      .data$is_admin,
      .data$created_at) %>%
    dplyr::collect()

  app_user_uids <- app_users$user_uid

  # find the email address for all users of the app
  app_user_emails <- conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "users")) %>%
    dplyr::filter(.data$uid %in% app_user_uids) %>%
    dplyr::select(user_uid = .data$uid, .data$email) %>%
    dplyr::collect()

  app_users %>%
    dplyr::left_join(app_user_emails, by = "user_uid")


}

#' add a user to the app
#'
#'
#' @post /app-users
#'
function(req, res, email, app_uid, is_admin, req_user_uid) {

  user_limit <- NULL
  #if (isFALSE(req$is_billing_enabled)) {
  #  # billing is not enabled, so set the user limit to 10
  #  user_limit <- free_plan_user_limit
  #}

  err <- NULL
  tryCatch({

    DBI::dbWithTransaction(conn, {



      existing_user_uid <- DBI::dbGetQuery(
        conn,
        paste0("SELECT uid FROM ", schema, ".users WHERE account_uid=$1 AND email=$2"),
        params = list(
          req$account_uid,
          email
        )
      )


      # if user does not exist, add the user to the users table
      if (nrow(existing_user_uid) == 0) {

        user_uid <- uuid::UUIDgenerate()

        new_user_uid <- add_user(
          conn,
          req$account_uid,
          email,
          req_user_uid,
          req_user_uid,
          schema = schema,
          unique_user_limit = user_limit
        )

      } else {
        new_user_uid <- existing_user_uid$uid

        # check if the user is already authorized to access this app
        existing_app_user <- DBI::dbGetQuery(
          conn,
          paste0("SELECT user_uid from ", schema, ".app_users WHERE user_uid=$1 AND app_uid=$2"),
          params = list(
            new_user_uid,
            app_uid
          )
        )

        # if user is already authorized to access this app, throw an error
        if (nrow(existing_app_user) != 0) {
          stop("user is already authorized to access app", call. = FALSE)
        }

      }


      # add user to app_users
      DBI::dbExecute(
        conn,
        paste0(
          "INSERT INTO ", schema, ".app_users (
            uid,
            account_uid,
            app_uid,
            user_uid,
            is_admin,
            created_by,
            modified_by
          ) VALUES
          ( $1, $2, $3, $4, $5, $6, $7 )"
        ),
        params = list(
          uuid::UUIDgenerate(),
          req$account_uid,
          app_uid,
          new_user_uid,
          is_admin,
          req_user_uid,
          req_user_uid
        )
      )


      })
  }, error = function(err) {

    err <<- err

  })


  if (!is.null(err)) {
    if (err$message == "unique user limit exceeded") {
      res$status <- 402 # Payment Required
      return(list(
        error = "unique user limit exceeded"
      ))
    } else  if (err$message == "user is already authorized to access app"){

      res$status <- 405 # Method Not Allowed
      return(list(
        error = "user is already authorized to access app"
      ))
    } else {
      print(list(err = err))
      res$status <- 500 # Server Error
      return(list(
        error = "server error"
      ))
    }
  }



  return(list(
    status = "success"
  ))
}

#' update the app user
#'
#'
#' @put /app-users
#'
function(req, res, user_uid, app_uid, is_admin, req_user_uid) {

  update_app_user(
    conn,
    user_uid = user_uid,
    app_uid = app_uid,
    is_admin = is_admin,
    modified_by = req_user_uid,
    schema = schema
  )

  return(list(
    status = "success"
  ))
}

#' update the app user
#'
#'
#' @delete /app-users
#'
function(req, res, user_uid, app_uid, req_user_uid) {

  DBI::dbExecute(
    conn,
    paste0("DELETE FROM ", schema, ".app_users WHERE user_uid=$1 AND app_uid=$2"),
    params = list(
      user_uid,
      app_uid
    )
  )

  write_log(type = "info", message = "app user deleted")

  return(list(
    status = "success"
  ))
}

#' get the user invite for a specific app by email
#'
#' @get /invite-by-email
#'
#'
function(req, res, app_uid, email) {

  hold_user <- get_user_by_email(
    conn,
    account_uid = req$account_uid,
    email = email,
    schema = schema
  )


  invite <- NULL
  if (!is.null(hold_user)) {
    invite <- get_invite(
      conn,
      app_uid = app_uid,
      user_uid = hold_user$uid,
      schema = schema
    )
  }

  if (isTRUE(verbose)) {
    if (is.null(invite)) {
      write_log(type = "info", message = "invite is null")
    } else {
      write_log(type = "info", message = "invite found")
    }
  }

  if (is.null(invite)) {
    out <- list()
  } else {
    out <- list(
      email = email,
      user_uid = hold_user$uid,
      is_admin = invite$is_admin,
      created_at = invite$created_at
    )
  }

  out
}

#' get the user invite for a specific app by user_uid
#'
#' @get /invites
#'
#'
function(req, res, app_uid, user_uid) {

  get_invite(
    conn,
    app_uid = app_uid,
    user_uid = user_uid,
    schema = schema
  )
}








#' get the sessions by cookie
#'
#'
#' @get /session-by-cookie
#'
function(req, res, hashed_cookie, app_uid) {

  # get the session
  signed_in_sessions <- DBI::dbGetQuery(
    conn,
    paste0('SELECT uid AS session_uid, user_uid, email, email_verified, app_uid, signed_in_as FROM ',
           schema, '.sessions WHERE hashed_cookie=$1 AND is_signed_in=$2 AND account_uid=$3'),
    params = list(
      hashed_cookie,
      TRUE,
      req$account_uid
    )
  )

  session_out <- NULL
  if (nrow(signed_in_sessions) > 0) {

    # confirm that user is invited
    invite <- get_invite(
      conn,
      app_uid,
      signed_in_sessions$user_uid[1],
      schema = schema
    )

    if (is.null(invite)) {
      return(NULL)
    }

    session_out <- list(
      "user_uid" = signed_in_sessions$user_uid[1],
      "email" = signed_in_sessions$email[1],
      "email_verified" = signed_in_sessions$email_verified[1],
      "is_admin" = invite$is_admin,
      "hashed_cookie" = hashed_cookie
    )

    app_session <- signed_in_sessions %>%
      dplyr::filter(.data$app_uid == .env$app_uid)

    if (nrow(app_session) == 0) {
      # user was signed into another app and came over to this app, so add a session for this app
      session_out$session_uid <- uuid::UUIDgenerate()

      add_session(conn, session_out, app_uid, schema = schema)

      session_out$signed_in_as <- NA
    } else if (nrow(app_session) == 1) {

      session_out$session_uid <- app_session$session_uid
      session_out$signed_in_as <- app_session$signed_in_as
    } else {
      stop('error: too many sessions', call. = FALSE)
    }
  }

  session_out
}




#' add a session to the sessions table
#'
#'
#' @post /sessions
#'
function(req, res, data, app_uid) {

  # add the session to the "sessions" table
  DBI::dbExecute(
    conn,
    paste0('INSERT INTO ', schema, '.sessions (uid, account_uid, user_uid, email, email_verified,
    hashed_cookie, app_uid) VALUES ($1, $2, $3, $4, $5, $6, $7)'),
    list(
      data$session_uid,
      req$account_uid,
      data$user_uid,
      data$email,
      data$email_verified,
      data$hashed_cookie,
      app_uid
    )
  )

  return(list(
    sign_in_status = "success"
  ))
}

#' update a row in the sessions table
#'
#' @put /sessions
#'
function(req, res, session_uid, dat) {

  # generate the query based on the values in the `dat` list
  dat <- c(dat, list(modified_at = Sys.time()))
  hold_names <- names(dat)
  query_prep <- paste0(hold_names, "=$", seq_along(hold_names))
  query_prep <- paste(query_prep, collapse = ", ")

  query <- paste0(
    paste0('UPDATE ', schema, '.sessions SET '),
    query_prep, ' WHERE uid=$',
    length(hold_names) + 1,
    ' AND account_uid=$',
    length(hold_names) + 2
  )

  # convert NULL to NA
  dat <- lapply(dat, function(x) {
    if (is.null(x)) NA else x
  })


  DBI::dbExecute(
    conn,
    query,
    params = c(
      unname(dat),
      list(session_uid),
      list(req$account_uid)
    )
  )

  return(list(
    status = "success"
  ))
}

#' sign out
#'
#'
#' @post /sign-out
#'
function(req, res, hashed_cookie, session_uid) {

  # sign the user out of all sessions with this cookie.  This will cause the user
  # to be signed out of all apps that they are signed into in the browser that they
  # have open
  DBI::dbExecute(
    conn,
    paste0("UPDATE ", schema, ".sessions SET is_active=$1, is_signed_in=$2 WHERE
           hashed_cookie=$3 AND account_uid=$4"),
    list(
      FALSE,
      FALSE,
      hashed_cookie,
      req$account_uid
    )
  )

  return(list(
    sign_out_status = "success"
  ))
}

#'
#'
#'
#' @post /actions
#'
function(req, res, type, session_uid) {

  if (!(type %in% c("set_inactive", "set_active"))) {
    res$status <- 400 # Bad Request
    return(list(
      error = "Invalid action type"
    ))
  }


  if (identical(type, "set_inactive")) {
    DBI::dbExecute(
      conn,
      paste0("UPDATE ", schema, ".sessions SET is_active=$1 WHERE uid=$2 AND account_uid=$3"),
      list(
        FALSE,
        session_uid,
        req$account_uid
      )
    )
  }

  if (identical(type, "set_active")) {
    DBI::dbExecute(
      conn,
      paste0("UPDATE ", schema, ".sessions SET is_active=$1 WHERE uid=$2 AND account_uid=$3"),
      list(
        TRUE,
        session_uid,
        req$account_uid
      )
    )
  }

  # log the action
  write_log(type = "info", message = type)

  return(list(
    session_action_update = "success"
  ))
}



#' get the number of sessions per day
#'
#'
#' @get /daily-sessions
#'
function(req, res, app_uid) {

  start_date <- lubridate::today(tzone = "America/New_York") - lubridate::days(30)


  if (identical(log_file, "stdout")) {
    # TODO: this needs to be updated for our new logging method for tracking user
    # actions

  } else {
    out <- read.table(file = log_file)
  }

  out
}

#' get the last active time for all app users
#'
#'
#' @get /last-active-session-time
#'
function(req, res, app_uid) {

  #get_last_active_session_time(conn, app_uid, schema = schema)
  # find the most recent session for each user.  Users who have not yet signed in
  # will not have any sessions, so they won't have a row in the below data frame
  conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "sessions")) %>%
    dplyr::filter(.data$app_uid == .env$app_uid) %>%
    dplyr::collect() %>%
    dplyr::group_by(.data$user_uid) %>%
    dplyr::filter(.data$modified_at == max(.data$modified_at, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::select(
      .data$user_uid,
      last_sign_in_at = .data$modified_at
    )
}

#' get the active users for an app
#'
#'
#' @get /active-users
#'
function(req, res, app_uid) {

  conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "sessions")) %>%
    dplyr::filter(
      .data$app_uid == .env$app_uid,
      .data$is_active == TRUE
    ) %>%
    dplyr::distinct(.data$email) %>%
    dplyr::collect()
}
