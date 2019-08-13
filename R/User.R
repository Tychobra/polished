#' User
#'
#' R6 class to track the polish user.  An instance of this class named `polish__user` should
#' be created in "global.R" of the Shiny app.
#'
#' @export
#'
#' @importFrom R6 R6Class
#' @importFrom httr GET content stop_for_status
#' @importFrom jsonlite fromJSON
#'
#'
#'
#'
User <-  R6::R6Class(
  classname = "User",
  public = list(
    initialize = function(firebase_functions_url, firebase_auth_token, app_name, polished_session) {
      stopifnot(length(firebase_functions_url) == 1 && is.character(firebase_functions_url))
      stopifnot(length(firebase_auth_token) == 1 && is.character(firebase_auth_token))
      stopifnot(length(app_name) == 1 && is.character(app_name))
      stopifnot(length(polished_session) == 1)

      self$firebase_functions_url <- firebase_functions_url

      self$token <- firebase_auth_token

      self$app_name <- app_name

      self$sign_in_with_token(firebase_auth_token)

      stopifnot(isTRUE(private$is_authed))

      private$polished_session <- polished_session

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
    set_signed_in_as = function(email) {

      # firebase function callable via url
      url_out <- paste0(
        self$firebase_functions_url,
        "getUserData?email=", private$email,
        "&signed_in_as_email=", email,
        "&app_name=", self$app_name
      )

      user_response <- httr::GET(url_out)
      httr::warn_for_status(user_response)
      user_text <- httr::content(user_response, "text")
      user <- jsonlite::fromJSON(user_text)

      if (is.null(user)) {
        private$signed_in_as <- NULL
      } else {
        private$signed_in_as <- user
      }

      invisible(self)
    },
    refreshEmailVerification = function() {

      url_out <- paste0(self$firebase_functions_url, "getUser?uid=", private$uid)
      user_response <- httr::GET(url_out)
      httr::warn_for_status(user_response)
      user_text <- httr::content(user_response, "text")
      user <- jsonlite::fromJSON(user_text)

      private$email_verified <- user$emailVerified

      invisible(self)
    },
    deleteRole = function(role) {

      if (!isTRUE(self$get_is_admin())) {

        return(list(
          "status" = 500,
          "message" = "error: user not authorized"
        ))

      } else {
        tryCatch({
          url_out <- paste0(self$firebase_functions_url, "deleteUserRole")
          r <- httr::GET(
            url_out,
            query = list(
              app_name = self$app_name,
              role = role
            )
          )
          httr::stop_for_status(r)
          role_delete_text <- httr::content(r, "text")
          role_delete_text <- jsonlite::fromJSON(role_delete_text)

          return(list(
            "status" = 200,
            "message" = "role successfully deleted"
          ))
        }, error = function(e) {
          print("error in 'deleteUserRole'")
          print(e)

          return(list(
            "status" = 500,
            "message" = e
          ))
        })

      }

    },
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
    get_uid = function() {
      private$uid
    },
    get_signed_in_as = function() {
      private$signed_in_as
    },
    clear_signed_in_as = function() {
      private$signed_in_as <- NULL
    },
    get_polished_session = function() {
      private$polished_session
    }
  ),
  private = list(
    email = character(0),
    is_admin = FALSE,
    role = character(0),
    is_authed = "authorizing",
    email_verified = FALSE,
    uid = character(0),
    # optional use to sign in as
    signed_in_as = NULL,
    polished_session = numeric(0)
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
    find_user_by_uid = function(uid, polished_session) {
      if (length(self$users) == 0 || is.null(uid)) return(NULL)

      user_out <- NULL

      for (i in seq_along(self$users)) {

        if (self$users[[i]]$get_uid() == uid && self$users[[i]]$get_polished_session() == polished_session) {
          user_out <- self$users[[i]]
        }
      }

      user_out
    },
    remove_user_by_uid = function(uid, polished_session) {
      if (length(self$users) == 0 || is.null(uid)) return(NULL)

      for (i in seq_along(self$users)) {

        if (self$users[[i]]$get_uid() == uid && self$users[[i]]$get_polished_session() == polished_session) {
          self$users[[i]] <- NULL

          break
        }
      }

      invisible(self)
    }
  )

)

.global_users <- Users$new()
