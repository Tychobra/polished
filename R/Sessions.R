

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
#'
Sessions <-  R6::R6Class(
  classname = 'Sessions',
  public = list(
    app_name = character(0),
    firebase_functions_url = character(0),
    conn = NULL,
    # Session configuration function.  This must be executed in global.R of the Shiny app.
    #
    # @param app_name the name of the app
    # @param firebase_functions_url the firebase function url
    # @param conn the database connection
    # @param authorization_level whether the app should be accessible to "all" users in the
    # "polished.users" table, or if it should only be accessible to users as defined in the
    # "app_users" table. Valid options are "app" or "all".  Defaults to "app".
    #
    config = function(
      app_name,
      firebase_functions_url = NULL,
      conn = NULL,
      authorization_level = 'app'
    ) {

      self$app_name <- app_name
      self$firebase_functions_url <- firebase_functions_url
      self$conn <- conn
      private$authorization_level <- authorization_level

      invisible(self)
    },
    sign_in = function(firebase_token, token) {
      conn <- self$conn
      # firebase function callable via url
      url_out <- paste0(self$firebase_functions_url, "sign_in_firebase")

      user <- NULL
      tryCatch({
        response <- httr::GET(
          url_out,
          query = list(
            token = firebase_token
          )
        )

        httr::warn_for_status(response)
        user_text <- httr::content(response, "text")
        user <- jsonlite::fromJSON(user_text)

      }, error = function(e) {
        print('error signing in')
        print(e)
      })


      new_session <- NULL

      if (!is.null(user)) {

        new_session <- list(
          email = user$email,
          firebase_uid = user$user_id,
          email_verified = user$email_verified
        )

        tryCatch({
          # confirm that user is invited
          invite <- self$get_invite_by_email(new_session$email)

          # find the users roles
          roles_out <- self$get_roles(invite$user_uid)

          new_session$is_admin <- invite$is_admin
          new_session$user_uid <- invite$user_uid
          new_session$roles <- roles_out

          # update the last sign in time
          DBI::dbExecute(
            self$conn,
            "UPDATE polished.app_users SET last_sign_in_at=$1 WHERE user_uid=$2 AND app_name=$3",
            params = list(
              tychobratools::time_now_utc(),
              invite$user_uid,
              self$app_name
            )
          )
        }, error = function(e) {

          print(e)
          new_session <<- NULL
        })



        new_session$token <- token

        # add the session to the 'sessions' table
        private$add(new_session)
      }

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
        stop(sprintf('user "%s" is not authoized to access "%s"', email, self$app_name))
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


          private$add(session_out)
          session_out$signed_in_as <- NA
        } else if (nrow(app_session) == 1) {

          # set the session from inactive to active
          #self$set_active(app_session$session_uid)

          session_out$session_uid <- app_session$session_uid
          session_out$signed_in_as <- app_session$signed_in_as
        } else {
          stop('error: too many sessions')
        }

        return(session_out)
      }

    },
    list = function() {

      out <- dbGetQuery(
        self$conn,
        "SELECT * FROM polished.active_sessions"
      )

      return(out)
    },
    refresh_email_verification = function(token, firebase_uid) {

      url_out <- paste0(self$firebase_functions_url, "get_user")
      response <- httr::GET(
        url_out,
        query = list(
          uid = firebase_uid
          #token = firebase_token
        )
      )
      httr::warn_for_status(response)
      email_verified_text <- httr::content(response, "text")
      email_verified <- jsonlite::fromJSON(email_verified_text)

      private$sessions[[token]]$email_verified <- email_verified

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

    },
    sign_out = function(session_uid) {
      dbExecute(
        self$conn,
        'UPDATE polished.sessions SET is_active=$1, is_signed_in=$2 WHERE uid=$2',
        list(
          FALSE,
          FALSE,
          session_uid
        )
      )
    }
  ),
  private = list(
    add = function(session) {

      uid <- if (is.null(session$session_uid)) create_uid() else session$session_uid
      dbExecute(
        self$conn,
        'INSERT INTO polished.sessions (uid, user_uid, firebase_uid, email, email_verified, token, app_name) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        list(
          uid,
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
    authorization_level = "app" # or "all"
  )
)

.global_sessions <- Sessions$new()




