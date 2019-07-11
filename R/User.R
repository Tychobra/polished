#' User
#'
#' R6 class to track the polish user.  An instance of this class named `polish__user` should
#' be created in "global.R" of the Shiny app.
#'
#' @export
#'
#' @importFrom R6 R6Class
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#'
#' @examples
#'
#' user <- User$new(
#'   "https://us-central1-gatsby-firebase-5adaa.cloudfunctions.net/signInWithToken",
#'   "eyJhbGciOiJSUzI1NiIsImtpZCI6IjY2NDNkZDM5ZDM4ZGI4NWU1NjAxN2E2OGE3NWMyZjM4YmUxMGM1MzkiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcG9saXNoLXRlbXBsYXRlIiwiYXVkIjoicG9saXNoLXRlbXBsYXRlIiwiYXV0aF90aW1lIjoxNTU4NDkwNzA2LCJ1c2VyX2lkIjoiNUlseEpHNENnYU03M0lka3lDWDBEeGRxZVNoMSIsInN1YiI6IjVJbHhKRzRDZ2FNNzNJZGt5Q1gwRHhkcWVTaDEiLCJpYXQiOjE1NTg5NjMxMjYsImV4cCI6MTU1ODk2NjcyNiwiZW1haWwiOiJhbmR5Lm1lcmxpbm9AdHljaG9icmEuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsiYW5keS5tZXJsaW5vQHR5Y2hvYnJhLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.eM1fvVBgIybL1X4Spq3Kwzt3EQNSqi9I8njXxf_1OEvgY7zRrYiyxNjCaEhDbdpeTN7rX84YldN8PtfBgsO9BXx0XAZsAqpuWkj5U2pKDHddzr2bk"
#' )
#'
#' user$get_is_authed()
#'
#' user$sign_in_with_token("invalid_token")
#'
#' # The below line of code will only work while the below token is still valid.
#' #user$sign_in_with_token("eyJhbGciOiJSUzI1NiIsImtpZCI6IjY2NDNkZDM5ZDM4ZGI4NWU1NjAxN2E2OGE3NWMyZjM4YmUxMGM1MzkiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcG9saXNoLXRlbXBsYXRlIiwiYXVkIjoicG9saXNoLXRlbXBsYXRlIiwiYXV0aF90aW1lIjoxNTU4NDkwNzA2LCJ1c2VyX2lkIjoiNUlseEpHNENnYU03M0lka3lDWDBEeGRxZVNoMSIsInN1YiI6IjVJbHhKRzRDZ2FNNzNJZGt5Q1gwRHhkcWVTaDEiLCJpYXQiOjE1NTg5NjMxMjYsImV4cCI6MTU1ODk2NjcyNiwiZW1haWwiOiJhbmR5Lm1lcmxpbm9AdHljaG9icmEuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsiYW5keS5tZXJsaW5vQHR5Y2hvYnJhLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.eM1fvVBgIybL1X4Spq3Kwzt3EQNSqi9I8njXxf_1OEvgY7zRrYiyxNjCaEhDbdpeTN7rX84YldN8PtfBgsO9BXx0XAZsAqpuWkj5U2pKDHddzr2bk-797o4Ppgknvp4rZcQCoW2E5B15YJ1ksHNZHLoejp7bKC83p4XThoCIjbaHzDik8-rlN8WUUrSPD0asG7CRhjNhJOIBQlphbLFhYqwTRid-XsgALG8SSjK-oT0ZzXJ0b3q7Wm2nUgbAkAUyErYlTO-WzScFUdjWLvvIhqjzeTD2Ll58zfJGSfqOuRMLUXJ1NmeARl-2cMw0gpN_HA-VSu_BgH1RR0VZFqehVA")
#'
User <-  R6::R6Class(
  classname = "User",
  public = list(
    initialize = function(firebase_functions_url, firebase_auth_token, app_name) {
      stopifnot(length(firebase_functions_url) == 1 && is.character(firebase_functions_url))
      stopifnot(length(firebase_auth_token) == 1 && is.character(firebase_auth_token))
      stopifnot(length(app_name) == 1 && is.character(app_name))

      self$firebase_functions_url <- firebase_functions_url

      self$token <- firebase_auth_token

      self$app_name <- app_name

      self$sign_in_with_token(firebase_auth_token)

      stopifnot(isTRUE(private$is_authed))

      invisible(self)
    },
    firebase_functions_url = character(0),
    token = character(0),
    app_name = character(0),
    sign_in_with_token = function(firebase_auth_token) {

      # firebase function callable via url
      url_out <- paste0(self$firebase_functions_url, "signInWithToken?token=", firebase_auth_token, "&app_name=", self$app_name)
      user_response <- httr::GET(url_out)
      user_text <- httr::content(user_response, "text")
      user <- jsonlite::fromJSON(user_text)


      if (is.null(user)) {
        private$is_authed <- FALSE
        private$email <- character(0)
        private$is_admin <- FALSE
        private$role <- character(0)
        private$email_verified <- FALSE
        private$uid <- character(0)
      } else {
        private$is_authed <- TRUE
        private$email <- user$email
        private$is_admin <- user$is_admin
        private$role <- user$role
        private$email_verified <- user$email_verified
        private$uid <- user$uid
      }

      invisible(self)
    },
    refreshEmailVerification = function() {

      url_out <- paste0(self$firebase_functions_url, "getUser?uid=", private$uid)
      user_response <- httr::GET(url_out)
      user_text <- httr::content(user_response, "text")
      user <- jsonlite::fromJSON(user_text)

      private$email_verified <- user$emailVerified
    },
    #set_token = function(token) {
    #  self$token <- token
    #  invisible(self)
    #},
    get_token = function() {
      self$token
    },
    get_is_authed = function() {
      private$is_authed
    },
    get_email = function() {
      private$email
    },
    get_is_admin = function() {
      private$is_admin
    },
    get_role = function() {
      private$role
    },
    get_email_verified = function() {
      private$email_verified
    },
    set_is_authed = function(auth_state) {
      private$is_authed <- auth_state
    },
    get_uid = function() {
      private$uid
    }
  ),
  private = list(
    email = character(0),
    is_admin = FALSE,
    role = character(0),
    is_authed = "authorizing",
    email_verified = FALSE,
    uid = character(0)
  )
)

#' Users
#'
#' R6 class to track the polish user.  An instance of this class named `polish__user` should
#' be created in "global.R" of the Shiny app.
#'
#' @export
#'
#' @importFrom R6 R6Class
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#'
Users <-  R6::R6Class(
  classname = "Users",
  public = list(

    # list of instances of `User`
    users = vector("list", length = 0),
    add_user = function(user) {
      self$users[[length(self$users) + 1]] <- user
      invisible(self)
    },
    find_user_by_uid = function(uid) {
      if (length(self$users) == 0 || is.null(uid)) return(NULL)

      user_out <- NULL

      for (i in seq_along(self$users)) {

        if (self$users[[i]]$get_uid() == uid) {
          user_out <- self$users[[i]]
        }
      }

      user_out
    },
    remove_user_by_uid = function(uid) {
      if (length(self$users) == 0 || is.null(uid)) return(NULL)

      for (i in seq_along(self$users)) {

        if (self$users[[i]]$get_uid() == uid) {
          self$users[[i]] <- NULL

          break
        }
      }

      invisible(self)
    }
  )

)

.global_users <- Users$new()
