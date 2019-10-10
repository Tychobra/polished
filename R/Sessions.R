

#' Sessions
#'
#' R6 class to track the polished sessions
#'
#' @export
#'
#' @importFrom R6 R6Class
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#' @importFrom digest digest
#'
Sessions <-  R6::R6Class(
  classname = "Sessions",
  public = list(
    app_name = character(0),
    firebase_functions_url = character(0),
    config = function(app_name, firebase_functions_url = NULL) {

      self$app_name <- app_name
      self$firebase_functions_url <- firebase_functions_url

      invisible(self)
    },
    sign_in = function(conn, firebase_token) {

      # firebase function callable via url
      url_out <- paste0(self$firebase_functions_url, "sign_in_firebase")
      response <- httr::GET(
        url_out,
        query = list(
          token = firebase_token
        )
      )

      httr::warn_for_status(response)
      user_text <- httr::content(response, "text")
      user <- jsonlite::fromJSON(user_text)

      new_session <- NULL

      if (!is.null(user)) {

        new_session <- list(
          email = user$email,
          firebase_uid = user$user_id,
          email_verified = user$email_verified
        )

        tryCatch({
          # confirm that user is invited
          invite <- self$get_invite(conn, new_session$email)

          # find the users roles
          roles_out <- self$get_roles(conn, invite$user_uid)

          new_session$is_admin <- invite$is_admin
          new_session$uid <- invite$user_uid
          new_session$roles <- roles_out

          # update the last sign in time
          DBI::dbExecute(
            conn,
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


        # geneate a session token
        if (!is.null(new_session)) {
          token <- create_uid()

          new_session$token <- token

          private$add(new_session)
        }
      }

      return(new_session)
    },
    get_invite = function(conn, email) {

      invite <- NULL
      DBI::dbWithTransaction(conn, {

        user_db <- DBI::dbGetQuery(
          conn,
          "SELECT * FROM polished.users WHERE email=$1",
          params = list(
            email
          )
        )


        if (nrow(user_db) != 1) {
          stop('unable to find users in "users" table')
        }

        invite <- DBI::dbGetQuery(
          conn,
          "SELECT * FROM polished.app_users WHERE user_uid=$1 AND app_name=$2",
          params = list(
            user_db$uid,
            self$app_name
          )
        )

        if (nrow(invite) != 1) {
          stop(sprintf('user "%s" is not authoized to access "%s"', email, self$app_name))
        }
      })

      return(invite)
    },
    # return a character vector of the user's roles
    get_roles = function(conn, user_uid) {
      roles <- character(0)
      DBI::dbWithTransaction(conn, {


        role_names <- DBI::dbGetQuery(
          conn,
          "SELECT uid, name FROM polished.roles WHERE app_name=$1",
          params = list(
            self$app_name
          )
        )

        role_uids <- DBI::dbGetQuery(
          conn,
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
      if (length(private$sessions) == 0) return(NULL)

      private$sessions[[token]]
    },
    remove = function(token) {
      if (length(private$sessions) == 0) invisible(self)

      private$sessions[[token]] <- NULL

      invisible(self)
    },
    list = function() {
      private$sessions
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
    log_session = function(conn, token, user_uid) {

      tryCatch({
        DBI::dbExecute(
          conn,
          "INSERT INTO polished.sessions ( app_name, user_uid, token ) VALUES ( $1, $2, $3 )",
          params = list(
            self$app_name,
            user_uid,
            token
          )
        )
      }, error = function(e) {
        print(e)

      })

    },
    set_signed_in_as = function(token, signed_in_as) {

      private$sessions[[token]]$signed_in_as <- signed_in_as

      invisible(self)
    },
    clear_signed_in_as = function(token) {

      if (!is.null(private$sessions[[token]]$signed_in_as)) {
        private$sessions[[token]]$signed_in_as <- NULL
      }

      invisible(self)
    }
  ),
  private = list(
    add = function(session) {
      private$sessions[[session$token]] <- session
      invisible(self)
    },
    sessions = vector("list", length = 0)
  )

)

.global_sessions <- Sessions$new()

