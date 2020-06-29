
api_get_invite_by_email <- function(url, api_key, email, app_uid) {


  res <- httr::GET(
    url = paste0(url, "/invite-by-email"),
    query = list(
      email = email,
      app_uid = app_uid
    ),
    httr::authenticate(
      user = api_key,
      password = ""
    )
  )

  httr::stop_for_status(res)

  invite <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  # API returns a length 0 list when there is no invite
  if (length(invite) == 0) {
    invite <- NULL
  }

  invite
}

api_get_invite <- function(url, api_key, app_uid, user_uid) {
  res <- httr::GET(
    url = paste0(url, "/invites"),
    query = list(
      app_uid = app_uid,
      user_uid = user_uid
    ),
    httr::authenticate(
      user = api_key,
      password = ""
    )
  )

  httr::stop_for_status(res)

  invite <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  # API returns a length 0 list when there is no invite
  if (length(invite) == 0) {
    invite <- NULL
  }

  invite
}

#' R6 class to track polished sessions
#'
#' @description
#' An instance of this class handles the 'polished' user sessions for each 'shiny'
#' app using 'polished'.  The 'shiny' developer should not need to interact with
#' this class directly.
#'
#'
#' @importFrom R6 R6Class
#' @importFrom httr GET content warn_for_status POST
#' @importFrom jsonlite fromJSON
#' @importFrom digest digest
#' @importFrom jose jwt_decode_sig
#' @importFrom lubridate with_tz minutes
#'
#'
Sessions <-  R6::R6Class(
  classname = 'Sessions',
  public = list(
    hosted_url = character(0),
    app_name = character(0),
    conn = NULL,
    firebase_config = NULL,
    is_invite_required = TRUE,
    api_key = NULL,
    sign_in_providers = character(0),
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
      app_name,
      api_key,
      firebase_config = NULL,
      admin_mode = FALSE,
      is_invite_required = TRUE,
      api_url = "https://api.polished.tech",
      sign_in_providers = c(
        "google",
        "email"
      )
    ) {

      if (!(length(app_name) == 1 && is.character(app_name))) {
        stop("invalid `app_name` argument passed to `global_sessions_config()`", call. = FALSE)
      }

      if (!(length(api_url) == 1 && is.character(api_url))) {
        stop("invalid `api_url` argument passed to `global_sessions_config()`", call. = FALSE)
      }

      if (!(length(sign_in_providers) >= 1 && is.character(sign_in_providers))) {
        stop("invalid `sign_in_providers` argument passed to `global_sessions_config()`", call. = FALSE)
      }


      self$api_key <- api_key
      self$hosted_url <- api_url
      self$sign_in_providers <- sign_in_providers

      if (is.null(firebase_config)) {
        # set to the default polished Firebase project if app is using polished
        # hosted, but no Firebase credentials provided.  This allows users to get up and
        # running quickly without needing to create a Firebase project, but for
        # production Shiny apps, the user should
        self$firebase_config <- list(
          apiKey = "AIzaSyAlrehX1g0irhCKq5MfmOE96z8lNprbbnk",
          authDomain = "polished-hosted.firebaseapp.com",
          projectId = "polished-hosted"
        )

        # print warning message to user that they need to create their own Firebase
        # project for polished before deploying to production.
        warning("
          You are using the default Firebase project with polished.
          You must confiure polished with your own Firebase project
          before using polished in production.
          Instruction here - https://polished.tech/docs/firebase-setup
        ")


      } else {
        if (length(firebase_config) != 3 ||
            !all(names(firebase_config) %in% c("apiKey", "authDomain", "projectId"))) {
          stop("invalid `firebase_config` argument passed to `global_sessions_config()`", call. = FALSE)
        }
        self$firebase_config <- firebase_config
      }



      # get the app uid
      res <- httr::GET(
        url = paste0(self$hosted_url, "/apps"),
        query = list(
          app_name = app_name
        ),
        httr::authenticate(
          user = self$api_key,
          password = ""
        )
      )

      app <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )

      status_out <- httr::status_code(res)

      if (!identical(status_out, 200L)) {
        stop(app, call. = FALSE)
      }

      self$app_name <- app$uid



      if (!(length(admin_mode) == 1 && is.logical(admin_mode))) {
        stop("invalid `admin_mode` argument passed to `global_sessions_config()`", call. = FALSE)
      }
      if (!(length(is_invite_required) == 1 && is.logical(is_invite_required))) {
        stop("invalid `is_invite_required` argument passed to `global_sessions_config()`", call. = FALSE)
      }


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
    #' * email_verified
    #' * is_admin
    #' * user_uid
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
          email_verified = decoded_jwt$email_verified
        )




        invite <- api_get_invite_by_email(
          self$hosted_url,
          self$api_key,
          new_session$email,
          self$app_name
        )

        if (isFALSE(self$is_invite_required) && is.null(invite)) {
          # if invite is not required, and this is the first time that the user is signing in,
          # then create the app_users
          res <- httr::POST(
            url = paste0(.global_sessions$hosted_url, "/app-users"),
            body = list(
              email = new_session$email,
              app_uid = self$app_name,
              is_admin = FALSE,
              req_user_uid = "00000000-0000-0000-0000-000000000000"
            ),
            httr::authenticate(
              user = .global_sessions$api_key,
              password = ""
            ),
            encode = "json"
          )

          httr::stop_for_status(res)

          invite <- api_get_invite_by_email(
            self$hosted_url,
            self$api_key,
            new_session$email,
            self$app_name
          )

        }

        if (is.null(invite)) {
          stop("[polished] error checking user invite", call. = FALSE)
        }


        new_session$is_admin <- invite$is_admin
        new_session$user_uid <- invite$user_uid


        new_session$hashed_cookie <- hashed_cookie
        new_session$session_uid <- uuid::UUIDgenerate()
        # add the session to the 'sessions' table
        private$add(new_session)
      }

      return(new_session)
    },
    get_invite_by_email = function(email) {

      invite <- NULL

      invite <- api_get_invite_by_email(
        self$hosted_url,
        self$api_key,
        email,
        self$app_name
      )

      return(invite)
    },
    find = function(hashed_cookie, page) {
      if (nchar(hashed_cookie) == 0) return(NULL)

      res <- httr::GET(
        url = paste0(self$hosted_url, "/session-by-cookie"),
        query = list(
          hashed_cookie = hashed_cookie,
          app_uid = self$app_name,
          page = page
        ),
        httr::authenticate(
          user = self$api_key,
          password = ""
        )
      )

      httr::stop_for_status(res)

      session_out <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )

      if (length(session_out) == 0) {
        session_out <- NULL
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
        stop("email verification user not found", call. = FALSE)
      } else {

        res <- httr::PUT(
          url = paste0(self$hosted_url, "/sessions"),
          httr::authenticate(
            user = self$api_key,
            password = ""
          ),
          body = list(
            session_uid = session_uid,
            dat = list(
              email_verified = email_verified
            )
          ),
          encode = "json"
        )

        httr::stop_for_status(res)
      }


      invisible(self)
    },
    set_signed_in_as = function(session_uid, signed_in_as, user_uid = NULL) {

      res <- httr::PUT(
        url = paste0(self$hosted_url, "/sessions"),
        httr::authenticate(
          user = self$api_key,
          password = ""
        ),
        body = list(
          session_uid = session_uid,
          dat = list(
            signed_in_as = signed_in_as
          ),
          user_uid = user_uid
        ),
        encode = "json"
      )

      httr::stop_for_status(res)

      invisible(self)
    },
    get_signed_in_as_user = function(user_uid) {

      invite <- api_get_invite(
        self$hosted_url,
        self$api_key,
        self$app_name,
        user_uid
      )

      email <- invite$email

      list(
        user_uid = user_uid,
        email = email,
        is_admin = invite$is_admin
      )
    },
    set_inactive = function(session_uid, user_uid) {



      res <- httr::POST(
        url = paste0(self$hosted_url, "/actions"),
        httr::authenticate(
          user = self$api_key,
          password = ""
        ),
        body = list(
          type = "set_inactive",
          session_uid = session_uid,
          user_uid = user_uid
        ),
        encode = "json"
      )

      httr::stop_for_status(res)
    },
    sign_out = function(hashed_cookie, session_uid) {

      res <- httr::POST(
        url = paste0(self$hosted_url, "/sign-out"),
        httr::authenticate(
          user = self$api_key,
          password = ""
        ),
        body = list(
          hashed_cookie = hashed_cookie,
          session_uid = session_uid
        ),
        encode = "json"
      )

      httr::stop_for_status(res)
    },
    get_admin_mode = function() {
      private$admin_mode
    }
  ),
  private = list(
    add = function(session_data) {

      # add session to "sessions" table via the API
      res <- httr::POST(
        url = paste0(self$hosted_url, "/sessions"),
        httr::authenticate(
          user = self$api_key,
          password = ""
        ),
        body = list(
          data = session_data,
          app_uid = self$app_name
        ),
        encode = "json"
      )

      session_content <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )

      httr::stop_for_status(res)

      invisible(self)
    },
    refresh_jwt_pub_key = function() {
      google_keys_resp <- httr::GET("https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com")

      # Error if we didn't get the keys successfully
      httr::stop_for_status(google_keys_resp)

      private$jwt_pub_key <- jsonlite::fromJSON(
        httr::content(google_keys_resp, "text", encoding = "UTF-8")
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
        stop("[polished] error decoding JWT", call. = FALSE)
      }

      curr_time <- as.numeric(Sys.time())
      # Verify the ID token
      # https://firebase.google.com/docs/auth/admin/verify-id-tokens
      if (!(as.numeric(decoded_jwt$exp) + private$firebase_token_grace_period_seconds > curr_time &&
            as.numeric(decoded_jwt$iat) < curr_time + private$firebase_token_grace_period_seconds &&
            as.numeric(decoded_jwt$auth_time) < curr_time + private$firebase_token_grace_period_seconds &&
            decoded_jwt$aud == self$firebase_config$projectId &&
            decoded_jwt$iss == paste0("https://securetoken.google.com/", self$firebase_config$projectId) &&
            nchar(decoded_jwt$sub) > 0)) {

        stop("[polished] error verifying JWT", call. = FALSE)
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




