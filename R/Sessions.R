



#' R6 class to track polished sessions
#'
#' @description
#' An instance of this class handles the polished user sessions for each Shiny
#' app using polished.  The Shiny developer should not need to interact with
#' this class directly.
#'
#' @export
#'
#' @importFrom R6 R6Class
#' @importFrom httr GET content warn_for_status
#' @importFrom jsonlite fromJSON
#' @importFrom digest digest
#' @importFrom DBI dbGetQuery dbWithTransaction dbExecute dbIsValid
#' @importFrom jose jwt_decode_sig
#' @importFrom lubridate with_tz minutes
#'
#'
Sessions <-  R6::R6Class(
  classname = 'Sessions',
  public = list(
    app_name = character(0),
    conn = NULL,
    firebase_project_id = character(0),
    is_invite_required = TRUE,

    #' @description
    #' polished Sessions configuration function
    #'
    #' @details
    #' This function is called via `global_sessions_config()` in global.R
    #' of all Shiny apps using polished.
    #'
    #' @inheritParams global_sessions_config
    #'
    config = function(
      conn = NULL,
      app_name = NULL,
      firebase_project_id = NULL,
      authorization_level = 'app',
      admin_mode = FALSE,
      is_invite_required = TRUE
    ) {
      if (!(length(firebase_project_id) == 1 && is.character(firebase_project_id))) {
        stop("invalid `firebase_project_id` argument passed to `global_sessions_config()`", call. = FALSE)
      }
      if (!(length(app_name) == 1 && is.character(app_name))) {
        stop("invalid `app_name` argument passed to `global_sessions_config()`", call. = FALSE)
      }
      if (!(length(authorization_level) == 1 && is.character(authorization_level))) {
        stop("invalid `authorization_level` argument passed to `global_sessions_config()`", call. = FALSE)
      }
      tryCatch({
        if (!DBI::dbIsValid(conn)) {
          stop("invalid `conn` argument passed to `global_sessions_config()`", call. = FALSE)
        }
      }, error = function(err) {
        stop("invalid `conn` argument passed to `global_sessions_config()`", call. = FALSE)
      })
      if (!(length(admin_mode) == 1 && is.logical(admin_mode))) {
        stop("invalid `admin_mode` argument passed to `global_sessions_config()`", call. = FALSE)
      }
      if (!(length(is_invite_required) == 1 && is.logical(is_invite_required))) {
        stop("invalid `is_invite_required` argument passed to `global_sessions_config()`", call. = FALSE)
      }



      self$app_name <- app_name
      self$conn <- conn
      private$authorization_level <- authorization_level
      self$firebase_project_id <- firebase_project_id
      private$admin_mode <- admin_mode
      self$is_invite_required <- is_invite_required

      private$refresh_jwt_pub_key()

      invisible(self)
    },


    #' @description
    #' verify the users Firebase JWT and store the session
    #'
    #' @param firebase_token the Firebase JWT.  This JWT is created client side
    #' (in JavaScript) via `firebase.auth()`.
    #' @param hashed_cookie the hashed polished cookie.  Used for tracking the user
    #' session.  This cookie is inserted into the "polished.sessions" table if the
    #' JWT is valid.
    #'
    #' @return NULL if sign in fails. If sign in is successful, a list containing the following:
    #' * email
    #' * firebase_uid
    #' * email_verified
    #' * is_admin
    #' * user_uid
    #' * roles
    #' * hashed_cookie
    #' * session_uid
    #' @md
    #'
    #'
    sign_in = function(firebase_token, hashed_cookie) {

      decoded_jwt <- NULL


      # check if the jwt public key has expired or if it is about to expire.  If it
      # is about to epire, go ahead and refresh to be safe.
      if (as.numeric(Sys.time()) + private$firebase_token_grace_period_seconds > private$jwt_pub_key_expires) {
        private$refresh_jwt_pub_key()
      }

      decoded_jwt <- private$verify_firebase_token(firebase_token)


      new_session <- NULL

      if (!is.null(decoded_jwt)) {

        new_session <- list(
          email = decoded_jwt$email,
          firebase_uid = decoded_jwt$user_id,
          email_verified = decoded_jwt$email_verified
        )




        invite <- self$get_invite_by_email(decoded_jwt$email)
        if (isFALSE(self$is_invite_required) && is.null(invite)) {
          # if invite is not required, and this is the first time that the user is signing in,
          # then we need to add their user info to the db
          create_app_user(self$conn, self$app_name, decoded_jwt$email)
          invite <- self$get_invite_by_email(new_session$email)
        }

        if (is.null(invite)) {
          stop("[polished] error checking user invite")
        }

        new_session$is_admin <- invite$is_admin
        new_session$user_uid <- invite$user_uid

        # find the users roles
        new_session$roles <- self$get_roles(invite$user_uid)


        new_session$hashed_cookie <- hashed_cookie
        new_session$session_uid <- uuid::UUIDgenerate()
        # add the session to the 'sessions' table
        private$add(new_session)

        dbExecute(
          self$conn,
          "INSERT INTO polished.session_actions (uid, session_uid, action) VALUES ($1, $2, $3)",
          list(
            uuid::UUIDgenerate(),
            new_session$session_uid,
            'sign_in'
          )
        )
      }

      return(new_session)
    },
    get_user_by_email = function(email) {
      user_out <- DBI::dbGetQuery(
        self$conn,
        "SELECT * FROM polished.users WHERE email=$1",
        params = list(
          email
        )
      )

      if (nrow(user_out) == 0) {
        return(NULL)
      }

      as.list(user_out)
    },
    get_invite_by_email = function(email) {

      invite <- NULL

      DBI::dbWithTransaction(self$conn, {

        user_db <- self$get_user_by_email(email)

        if (!is.null(user_db)) {
          invite <- self$get_invite_by_uid(user_db$uid)
        }


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
        return(NULL)
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
    find = function(hashed_cookie) {

      signed_in_sessions <- dbGetQuery(
        self$conn,
        'SELECT uid AS session_uid, user_uid, email, email_verified, firebase_uid, app_name, signed_in_as FROM polished.sessions WHERE hashed_cookie=$1 AND is_signed_in=$2',
        params = list(
          hashed_cookie,
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
          "hashed_cookie" = hashed_cookie
        )


        if (nrow(app_session) == 0) {
          # user was signed into another app and came over to this app, so add a session for this app
          session_out$session_uid <- uuid::UUIDgenerate()

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
    refresh_email_verification = function(session_uid, firebase_token) {

      email_verified <- NULL
      tryCatch({

        # check if the jwt public key has expired.  Add an extra minute to the
        # current time for padding before checking if the key has expired.
        if (Sys.time() + private$firebase_token_grace_period_seconds >
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
    set_signed_in_as = function(hashed_cookie, signed_in_as) {

      dbExecute(
        self$conn,
        'UPDATE polished.sessions SET signed_in_as=$1 WHERE hashed_cookie=$2 AND app_name=$3',
        params = list(
          signed_in_as$uid,
          hashed_cookie,
          self$app_name
        )
      )

      invisible(self)
    },
    clear_signed_in_as = function(session_uid) {

      dbExecute(
        self$conn,
        'UPDATE polished.sessions SET signed_in_as=$1 WHERE uid=$2',
        params = list(
          NA,
          session_uid
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
          uuid::UUIDgenerate(),
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
          uuid::UUIDgenerate(),
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
          uuid::UUIDgenerate(),
          session_uid,
          'sign_out'
        )
      )
    },
    get_admin_mode = function() {
      private$admin_mode
    }
  ),
  private = list(
    add = function(session) {

      dbExecute(
        self$conn,
        'INSERT INTO polished.sessions (uid, user_uid, firebase_uid, email, email_verified, hashed_cookie, app_name) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        list(
          session$session_uid,
          session$user_uid,
          session$firebase_uid,
          session$email,
          session$email_verified,
          session$hashed_cookie,
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
            private$jwt_pub_key_expires <- as.numeric(Sys.time()) + max_age
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
        # If a key isn't the right one for the Firebase token, then we get an error.
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

      curr_time <- as.numeric(Sys.time())
      # Verify the ID token
      # https://firebase.google.com/docs/auth/admin/verify-id-tokens
      if (!(as.numeric(decoded_jwt$exp) + private$firebase_token_grace_period_seconds > curr_time &&
            as.numeric(decoded_jwt$iat) < curr_time + private$firebase_token_grace_period_seconds &&
            as.numeric(decoded_jwt$auth_time) < curr_time + private$firebase_token_grace_period_seconds &&
            decoded_jwt$aud == self$firebase_project_id &&
            decoded_jwt$iss == paste0("https://securetoken.google.com/", self$firebase_project_id) &&
            nchar(decoded_jwt$sub) > 0)) {

        stop("[polished] error verifying JWT")
      }

      decoded_jwt
    },
    # Grace period to allow for clock skew between our clock and the server that generates the
    # firebase tokens.
    firebase_token_grace_period_seconds = 300,
    # when `admin_mode == TRUE` the user will be taken directly to the admin panel and signed in
    # as a special "admin" user.
    admin_mode = FALSE
  )
)

.global_sessions <- Sessions$new()




