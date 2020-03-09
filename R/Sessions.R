



#' Sessions
#'
#' R6 class to track the polished sessions
#'
#' @export
#'
#' @importFrom R6 R6Class
#' @importFrom httr GET content warn_for_status
#' @importFrom jsonlite fromJSON
#' @importFrom digest digest
#' @importFrom DBI dbGetQuery dbWithTransaction dbExecute
#' @importFrom jose jwt_decode_sig
#' @importFrom lubridate with_tz minutes
#'
Sessions <-  R6::R6Class(
  classname = 'Sessions',
  public = list(
    app_name = character(0),
    conn = NULL,
    firebase_project_id = NULL,
    # Session configuration function.  This must be executed in global.R of the Shiny app.
    #
    # @param app_name the name of the app
    # @param firebase_project_id the project ID for the Firebase project
    # @param conn the database connection
    # @param authorization_level whether the app should be accessible to "all" users in the
    # "polished.users" table, or if it should only be accessible to users as defined in the
    # "app_users" table. Valid options are "app" or "all".  Defaults to "app".
    #
    config = function(
      app_name,
      firebase_project_id = NULL,
      conn = NULL,
      authorization_level = 'app'
    ) {

      self$app_name <- app_name
      self$conn <- conn
      private$authorization_level <- authorization_level
      self$firebase_project_id <- firebase_project_id

      private$refresh_jwt_pub_key()

      invisible(self)
    },
    # the current time + 1 minute.  Used to check that the keys have not
    # expired.  Using time of 1 minute into the future to be safe.
    curr_time_1 = function() {
      lubridate::with_tz(Sys.time(), tzone = "UTC") + lubridate::minutes(1)
    },
    sign_in = function(firebase_token, token) {

      decoded_jwt <- NULL
      tryCatch({

        # check if the jwt public key has expired.
        curr_time <- self$curr_time_1()
        if (curr_time > private$jwt_pub_key_expires) {
          private$refresh_jwt_pub_key()
        }

        decoded_jwt <- private$verify_firebase_token(firebase_token)

      }, error = function(e) {
        print('[polished] error signing in')
        print(e)
      })


      new_session <- NULL

      if (!is.null(decoded_jwt)) {

        new_session <- list(
          email = decoded_jwt$email,
          firebase_uid = decoded_jwt$user_id,
          email_verified = decoded_jwt$email_verified
        )

        tryCatch({
          # confirm that user is invited
          invite <- self$get_invite_by_email(new_session$email)

          # find the users roles
          roles_out <- self$get_roles(invite$user_uid)

          new_session$is_admin <- invite$is_admin
          new_session$user_uid <- invite$user_uid
          new_session$roles <- roles_out

        }, error = function(e) {

          print(e)
          new_session <<- NULL
        })



        new_session$token <- token
        new_session$session_uid <- create_uid()
        # add the session to the 'sessions' table
        private$add(new_session)
      }

      dbExecute(
        self$conn,
        "INSERT INTO polished.session_actions (uid, session_uid, action) VALUES ($1, $2, $3)",
        list(
          create_uid(),
          new_session$session_uid,
          'sign_in'
        )
      )

      return(new_session)
    },
    get_invite_by_email = function(email) {

      invite <- NULL
      DBI::dbWithTransaction(self$conn, {

        user_db <- DBI::dbGetQuery(
          self$conn,
          "SELECT * FROM polished.users WHERE email=$1",
          params = list(
            email
          )
        )

        if (nrow(user_db) != 1) {
          stop(sprintf('unable to find "%s" in "users" table', email))
        }

        invite <- self$get_invite_by_uid(user_db$uid)
      })

      return(invite)
    },
    get_invite_by_uid = function(user_uid) {

      if (private$authorization_level == "app") {
        # authorization for this user is set at the Shiny app level, so only check this specific app
        # to see if the user is authorized
        invite <- DBI::dbGetQuery(
          self$conn,
          "SELECT * FROM polished.app_users WHERE user_uid=$1 AND app_name=$2",
          params = list(
            user_uid,
            self$app_name
          )
        )
      } else if (private$authorization_level == "all") {
        # if user is authoized to access any apps, they can access this app.
        # e.g. used for apps_dashboards where we want all users that are allowed to access any app to
        # be able to access the dashboard.
        invite <- DBI::dbGetQuery(
          self$conn,
          "SELECT * FROM polished.app_users WHERE user_uid=$1 LIMIT 1",
          params = list(
            user_uid
          )
        )
      }

      if (nrow(invite) != 1) {
        stop(sprintf('user "%s" is not authorized to access "%s"', user_uid, self$app_name))
      }

      invite
    },
    # return a character vector of the user's roles
    get_roles = function(user_uid) {
      roles <- character(0)
      DBI::dbWithTransaction(self$conn, {


        role_names <- DBI::dbGetQuery(
          self$conn,
          "SELECT uid, name FROM polished.roles WHERE app_name=$1",
          params = list(
            self$app_name
          )
        )

        role_uids <- DBI::dbGetQuery(
          self$conn,
          "SELECT role_uid FROM polished.user_roles WHERE user_uid=$1 AND app_name=$2",
          params = list(
            user_uid,
            self$app_name
          )
        )$role_uid

        roles <- role_names %>%
          dplyr::filter(uid %in% role_uids) %>%
          dplyr::pull(name)
      })

      roles
    },
    find = function(token) {

      signed_in_sessions <- dbGetQuery(
        self$conn,
        'SELECT uid AS session_uid, user_uid, email, email_verified, firebase_uid, app_name, signed_in_as FROM polished.sessions WHERE token=$1 AND is_signed_in=$2',
        params = list(
          token,
          TRUE
        )
      )

      session_out <- NULL
      if (nrow(signed_in_sessions) > 0) {



        # confirm that user is invited
        invite <- self$get_invite_by_uid(signed_in_sessions$user_uid[1])
        roles <- self$get_roles(signed_in_sessions$user_uid[1])

        app_session <- signed_in_sessions %>%
          filter(.data$app_name == self$app_name)

        # if user is not invited, the above `get_invite_by_uid()` function will throw an error.  If user is invited,
        # return the user session


        session_out <- list(
          "user_uid" = signed_in_sessions$user_uid[1],
          "email" = signed_in_sessions$email[1],
          "firebase_uid" = signed_in_sessions$firebase_uid[1],
          "email_verified" = signed_in_sessions$email_verified[1],
          "is_admin" = invite$is_admin,
          "roles" = roles,
          "token" = token
        )


        if (nrow(app_session) == 0) {
          # user was signed into another app and came over to this app, so add a session for this app
          session_out$session_uid <- create_uid()

          private$add(session_out)
          session_out$signed_in_as <- NA
        } else if (nrow(app_session) == 1) {

          session_out$session_uid <- app_session$session_uid
          session_out$signed_in_as <- app_session$signed_in_as
        } else {
          stop('error: too many sessions')
        }
      }

      return(session_out)
    },
    list = function() {

      out <- dbGetQuery(
        self$conn,
        "SELECT * FROM polished.active_sessions"
      )

      return(out)
    },
    refresh_email_verification = function(session_uid, firebase_token) {

      email_verified <- NULL
      tryCatch({

        # check if the jwt public key has expired.  Add an extra minute to the
        # current time for padding before checking if the key has expired.
        if (lubridate::with_tz(Sys.time(), tzone = "UTC") + lubridate::minutes(1) >
            private$jwt_pub_key_expires) {
          private$refresh_jwt_pub_key()
        }

        decoded_jwt <- private$verify_firebase_token(firebase_token)

        if (!is.null(decoded_jwt)) {
          email_verified <- decoded_jwt$email_verified
        }

      }, error = function(e) {
        print('[polished] error signing in')
        print(e)
      })

      if (is.null(email_verified)) {
        stop("email verification user not found")
      } else {
        dbExecute(
          self$conn,
          'UPDATE polished.sessions SET email_verified=$1 WHERE uid=$2',
          params = list(
            email_verified,
            session_uid
          )
        )
      }


      invisible(self)
    },
    set_signed_in_as = function(token, signed_in_as) {

      dbExecute(
        self$conn,
        'UPDATE polished.sessions SET signed_in_as=$1 WHERE token=$2 AND app_name=$3',
        params = list(
          signed_in_as$uid,
          token,
          self$app_name
        )
      )

      invisible(self)
    },
    clear_signed_in_as = function(token) {

      dbExecute(
        self$conn,
        'UPDATE polished.sessions SET signed_in_as=$1 WHERE token=$2 AND app_name=$3',
        params = list(
          NA,
          token,
          self$app_name
        )
      )

      invisible(self)
    },
    get_signed_in_as_user = function(user_uid) {

      email <- dbGetQuery(
        self$conn,
        'SELECT email FROM polished.users WHERE uid=$1',
        list(
          user_uid
        )
      )$email

      invite <- self$get_invite_by_uid(user_uid)

      roles <- self$get_roles(user_uid)

      list(
        user_uid = user_uid,
        email = email,
        is_admin = invite$is_admin,
        roles = roles
      )
    },
    set_inactive = function(session_uid) {

      dbExecute(
        self$conn,
        'UPDATE polished.sessions SET is_active=$1 WHERE uid=$2',
        list(
          FALSE,
          session_uid
        )
      )

      dbExecute(
        self$conn,
        "INSERT INTO polished.session_actions (uid, session_uid, action) VALUES ($1, $2, $3)",
        list(
          create_uid(),
          session_uid,
          'deactivate'
        )
      )

    },
    set_active = function(session_uid) {
      dbExecute(
        self$conn,
        'UPDATE polished.sessions SET is_active=$1 WHERE uid=$2',
        list(
          TRUE,
          session_uid
        )
      )

      dbExecute(
        self$conn,
        "INSERT INTO polished.session_actions (uid, session_uid, action) VALUES ($1, $2, $3)",
        list(
          create_uid(),
          session_uid,
          'activate'
        )
      )
    },
    sign_out = function(user_uid, session_uid) {


      dbExecute(
        self$conn,
        'UPDATE polished.sessions SET is_active=$1, is_signed_in=$2 WHERE user_uid=$3',
        list(
          FALSE,
          FALSE,
          user_uid
        )
      )

      dbExecute(
        self$conn,
        "INSERT INTO polished.session_actions (uid, session_uid, action) VALUES ($1, $2, $3)",
        list(
          create_uid(),
          session_uid,
          'sign_out'
        )
      )
    }
  ),
  private = list(
    add = function(session) {

      dbExecute(
        self$conn,
        'INSERT INTO polished.sessions (uid, user_uid, firebase_uid, email, email_verified, token, app_name) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        list(
          session$session_uid,
          session$user_uid,
          session$firebase_uid,
          session$email,
          session$email_verified,
          session$token,
          self$app_name
        )
      )

      invisible(self)
    },
    authorization_level = "app", # or "all"
    refresh_jwt_pub_key = function() {
      google_keys_resp <- httr::GET("https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com")

      # Error if we didn't get the keys successfully
      httr::stop_for_status(google_keys_resp)

      private$jwt_pub_key <- jsonlite::fromJSON(
        httr::content(google_keys_resp, "text")
      )


      # Decode the expiration time of the keys from the Cache-Control header
      cache_controls <- httr::headers(google_keys_resp)[["Cache-Control"]]
      if (!is.null(cache_controls)) {
        cache_control_elems <- strsplit(cache_controls, ",")[[1]]
        split_equals <- strsplit(cache_control_elems, "=")
        for (elem in split_equals) {

          if (length(elem) == 2 && trimws(elem[1]) == "max-age") {
            max_age <- as.numeric(elem[2])
            private$jwt_pub_key_expires <- lubridate::with_tz(Sys.time(), tzone = "UTC") + max_age
            break
          }

        }
      }
    },
    jwt_pub_key = NULL,
    # number of seconds that the public key will remain valid
    jwt_pub_key_expires = NULL,
    verify_firebase_token = function(firebase_token) {
      # Google sends us 2 public keys to authenticate the JWT.  Sometimes the correct
      # key is the first one, and sometimes it is the second.  I do not know how
      # to tell which key is the right one to use, so we try them both for now.
      decoded_jwt <- NULL
      for (key in private$jwt_pub_key) {
        # If a key isn't the right one for the token, then we get an error.
        # Ignore the errors and just don't set decoded_token if there's
        # an error. When we're done, we'll look at the the decoded_token
        # to see if we found a valid key.
        try({
          decoded_jwt <- jose::jwt_decode_sig(firebase_token, key)
          break
        }, silent=TRUE)
      }

      if (is.null(decoded_jwt)) {
        stop("[polished] error decoding JWT")
      }

      curr_time <- lubridate::with_tz(Sys.time(), tzone = "UTC")
      # Verify the ID token
      # https://firebase.google.com/docs/auth/admin/verify-id-tokens
      if (!(as.numeric(decoded_jwt$exp) > curr_time &&
            as.numeric(decoded_jwt$iat) < curr_time &&
            as.numeric(decoded_jwt$auth_time) < curr_time &&
            decoded_jwt$aud == self$firebase_project_id &&
            decoded_jwt$iss == paste0("https://securetoken.google.com/", self$firebase_project_id) &&
            nchar(decoded_jwt$sub) > 0)) {

        stop("[polished] error verifying JWT")
      }

      decoded_jwt
    }
  )
)

.global_sessions <- Sessions$new()




