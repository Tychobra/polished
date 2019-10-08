

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

      if (is.null(user)) {
        # user sign in failed
        return(NULL)
      } else {

        new_session <- list(
          email = user$email,
          firebase_uid = user$user_id,
          email_verified = user$email_verified
        )



        # check user authorization
        tryCatch({
          # confirm that user is invited
          DBI::dbWithTransaction(conn, {

            user_db <- DBI::dbGetQuery(
              conn,
              "SELECT * FROM polished.users WHERE email=$1",
              params = list(
                new_session$email
              )
            )


            if (nrow(user_db) != 1) {
              stop('unable to find uers in "users" table')
            } else {

              is_admin <- DBI::dbGetQuery(
                conn,
                "SELECT is_admin FROM polished.app_users WHERE user_uid=$1 AND app_name=$2",
                params = list(
                  user_db$uid,
                  self$app_name
                )
              )

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
                  user_db$uid,
                  self$app_name
                )
              )$role_uid

              roles_out <- role_names %>%
                dplyr::filter(uid %in% role_uids) %>%
                dplyr::pull(name)

              new_session$is_admin <- is_admin$is_admin
              new_session$uid <- user_db$uid
              new_session$roles <- roles_out

            }

            # update the last sign in time
            DBI::dbExecute(
              conn,
              "UPDATE polished.app_users SET last_sign_in_at=$1 WHERE user_uid=$2 AND app_name=$3",
              params = list(
                tychobratools::time_now_utc(),
                user_db$uid,
                self$app_name
              )
            )

          })
        }, error = function(e) {

          print(e)
          return(NULL)
        })




        # geneate a session token
        token <- create_uid()

        new_session$token <- token

        private$add(new_session)
      }

      return(new_session)
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

