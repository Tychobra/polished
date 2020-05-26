#' create_app_user
#'
#' Add the first user to the "polished" schema
#'
#' @param conn the database connection.
#' @param app_uid the name of the Shiny app.
#' @param email the email address of the first user.
#' @param is_admin boolean that defaults to FALSE.  Whether or not the user being created
#' is an admin.
#' @param created_by uid of the user creating this user.  If `NULL`, the default, then the
#' user uid of the user being created will be used.
#' @param modified_by uid of the user creating this user.  If `NULL`, the default, then the
#' value of `created_by` will be used.
#' @param schema the database schema
#' @param unique_user_limit a limit for the number of unique users allowed for the
#' account.  This is used with the polished.tech API.  Defaults to \code{NULL}.
#'
#' @export
#'
#' @importFrom DBI dbWithTransaction dbGetQuery dbExecute dbWriteTable
#'
#'
create_app_user <- function(conn, app_uid, email, is_admin = FALSE,
                            created_by = NULL, modified_by = NULL, schema = "polished",
                            unique_user_limit = NULL) {

  email <- tolower(email)
  email <- trimws(email)

  DBI::dbWithTransaction(conn, {



    if (is.null(.global_sessions$api_key)) {
      existing_user_uid <- DBI::dbGetQuery(
        conn,
        paste0("SELECT uid FROM ", schema, ".users WHERE email=$1"),
        params = list(email)
      )
    } else {

      # API selects unique users by email and the `create_by` column which works as the
      # account uid
      existing_user_uid <- DBI::dbGetQuery(
        conn,
        paste0("SELECT uid FROM ", schema, ".users WHERE email=$1 AND created_by=$2"),
        params = list(
          email,
          created_by
        )
      )
    }




    # if user does not exist, add the user to the users table
    if (nrow(existing_user_uid) == 0) {

      user_uid <- uuid::UUIDgenerate()

      if (is.null(created_by)) {
        created_by <- user_uid
      }

      if (is.null(modified_by)) {
        modified_by <- created_by
      }

      user_uid <- add_user(
        conn,
        email,
        created_by,
        modified_by,
        schema = schema,
        unique_user_limit = unique_user_limit
      )

    } else {
      user_uid <- existing_user_uid$uid

      if (is.null(created_by)) {
        created_by <- user_uid
      }

      # check if the user is already authorized to access this app
      existing_app_user <- DBI::dbGetQuery(
        conn,
        paste0("SELECT user_uid from ", schema, ".app_users WHERE user_uid=$1 AND app_uid=$2"),
        params = list(
          user_uid,
          app_uid
        )
      )

      # if user is already authorized to access this app, throw an error
      if (nrow(existing_app_user) != 0) {
        stop("user is already authorized to access app", call. = FALSE)
      }

    }

    # check if app already exists
    existing_app_uid <- DBI::dbGetQuery(
      conn,
      paste0("SELECT uid FROM ", schema, ".apps WHERE uid=$1"),
      params = list(app_uid)
    )

    if (nrow(existing_app_uid) == 0) {
      # if app does not exist, then create it
      add_app(
        conn = conn,
        app_uid = app_uid,
        app_name = app_uid,
        created_by = created_by,
        modified_by = created_by
      )
    }


    # add user to app_users
    DBI::dbExecute(
      conn,
      paste0("INSERT INTO ", schema, ".app_users ( uid, app_uid, user_uid, is_admin, created_by, modified_by) VALUES ( $1, $2, $3, $4, $5, $6 )"),
      params = list(
        uuid::UUIDgenerate(),
        app_uid,
        user_uid,
        is_admin,
        created_by,
        created_by
      )
    )


  })

}
