#' create_app_user
#'
#' Add the first user to the "polished" schema
#'
#' @param conn the database connection.
#' @param app_name the name of the Shiny app.
#' @param email the email address of the first user.
#' @param is_admin boolean that defaults to FALSE.  Whether or not the user being created
#' is an admin.
#' @param created_by uid of the user that creating this user.  If `NULL`, the default, then the
#' user uid of the user being created will be used.
#'
#' @export
#'
#' @importFrom DBI dbWithTransaction dbGetQuery dbExecute dbWriteTable
#'

#'
create_app_user <- function(conn, app_name, email, is_admin = FALSE, created_by = NULL) {

  email <- tolower(email)
  email <- trimws(email)

  DBI::dbWithTransaction(conn, {


    existing_user_uid <- DBI::dbGetQuery(
      conn,
      "SELECT uid FROM polished.users WHERE email=$1",
      params = list(email)
    )



    # if user does not exist, add the user to the users table
    if (nrow(existing_user_uid) == 0) {

      user_uid <- uuid::UUIDgenerate()

      if (is.null(created_by)) {
        created_by <- user_uid
      }

      DBI::dbExecute(
        conn,
        "INSERT INTO polished.users ( uid, email, created_by, modified_by ) VALUES ( $1, $2, $3, $4 )",
        params = list(
          user_uid,
          email,
          created_by,
          created_by
        )
      )

    } else {
      user_uid <- existing_user_uid$uid

      if (is.null(created_by)) {
        created_by <- user_uid
      }

      # check if the user is already authorized to access this app
      existing_app_user <- DBI::dbGetQuery(
        conn,
        "SELECT user_uid from polished.app_users WHERE user_uid=$1 AND app_name=$2",
        params = list(
          user_uid,
          app_name
        )
      )

      # if user is already authorized to access this app, throw an error
      if (nrow(existing_app_user) != 0) {
        stop(sprintf("%s is already authoized to access %s", email, app_name))
      }

    }

    # check if app already exists
    existing_app_uid <- DBI::dbGetQuery(
      conn,
      "SELECT app_name FROM polished.apps WHERE app_name=$1",
      params = list(app_name)
    )

    if (nrow(existing_app_uid) == 0) {
      # if app does not exist, then create it
      DBI::dbExecute(
        conn,
        "INSERT INTO polished.apps ( app_name, created_by, modified_by ) VALUES ( $1, $2, $3 )",
        params = list(
          app_name,
          created_by,
          created_by
        )
      )
    }


    # add user to app_users
    DBI::dbExecute(
      conn,
      "INSERT INTO polished.app_users ( uid, app_name, user_uid, is_admin, created_by, modified_by) VALUES ( $1, $2, $3, $4, $5, $6 )",
      params = list(
        uuid::UUIDgenerate(),
        app_name, # app_name
        user_uid, # user_uid
        is_admin,     # is_admin
        created_by, # created_by
        created_by  # modified_by
      )
    )


  })

}
