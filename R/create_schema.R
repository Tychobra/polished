#' create_schema
#'
#' create all the tables in the "polished" schema.  The "polished" schema contains the following tables.
#'  - users
#'  - apps
#'  - app_users
#'  - roles
#'  - user_roles
#'  - sessions
#'
#' @param conn the `RPostgres` database connection.  Only `RPostgres` is supported.
#'
#' @import DBI
#'
#' @export
#'
#'
create_schema <- function(conn) {

  create_users_table_query <- "CREATE TABLE polished.users (
    uid                            TEXT PRIMARY KEY,
    firebase_uid                   TEXT,
    email                          TEXT,
    created_by                     TEXT NOT NULL,
    created_at                     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by                    TEXT NOT NULL,
    modified_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )"


  create_apps_table_query <- "CREATE TABLE polished.apps (
    app_name              TEXT PRIMARY KEY,
    created_by            TEXT NOT NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by           TEXT NOT NULL,
    modified_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )"

  create_app_users_table_query <- "CREATE TABLE polished.app_users (
    uid                   TEXT PRIMARY KEY,
    app_name              TEXT REFERENCES polished.apps(app_name),
    user_uid              TEXT REFERENCES polished.users(uid),
    is_admin              BOOLEAN NOT NULL,
    last_sign_in_at       TIMESTAMPTZ,
    created_by            TEXT NOT NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by           TEXT NOT NULL,
    modified_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )"

  create_roles_table_query <- "CREATE TABLE polished.roles (
    uid                   TEXT PRIMARY KEY,
    name                  TEXT,
    app_name              TEXT REFERENCES polished.apps(app_name),
    created_by            TEXT NOT NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by           TEXT NOT NULL,
    modified_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )"

  create_user_roles_table_query <- "CREATE TABLE polished.user_roles (
    uid                    SERIAL PRIMARY KEY,
    user_uid               TEXT REFERENCES polished.users(uid),
    role_uid               TEXT REFERENCES polished.roles(uid),
    app_name               TEXT REFERENCES polished.apps(app_name),
    created_by             TEXT NOT NULL,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )"

  create_sessions_table_query <- "CREATE TABLE polished.sessions (
    uid                   SERIAL PRIMARY KEY,
    app_name              TEXT REFERENCES polished.apps(app_name),
    user_uid              TEXT REFERENCES polished.users(uid),
    token                 TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )"

  dbExecute(conn, "CREATE SCHEMA IF NOT EXISTS polished")
  dbExecute(conn, "DROP TABLE IF EXISTS polished.users CASCADE")
  dbExecute(conn, "DROP TABLE IF EXISTS polished.apps CASCADE")
  dbExecute(conn, "DROP TABLE IF EXISTS polished.roles CASCADE")
  dbExecute(conn, "DROP TABLE IF EXISTS polished.user_roles CASCADE")
  dbExecute(conn, "DROP TABLE IF EXISTS polished.app_users CASCADE")
  dbExecute(conn, "DROP TABLE IF EXISTS polished.sessions CASCADE")

  dbExecute(conn, create_users_table_query)
  dbExecute(conn, create_apps_table_query)
  dbExecute(conn, create_app_users_table_query)
  dbExecute(conn, create_roles_table_query)
  dbExecute(conn, create_user_roles_table_query)
  dbExecute(conn, create_sessions_table_query)
}

#' create_first_user
#'
#' Add the first user to the "polished" schema
#'
#' @param conn the database connection.
#' @param app_name the name of the Shiny app.
#' @param email the email address of the first user.
#'
#' @export
#'
#' @import DBI
#'
create_first_user <- function(conn, app_name, email) {

  user_uid <- create_uid()
  app_user_uid <- create_uid()

  # insert data entries for first user and app
  dbExecute(
    conn,
    "INSERT INTO polished.users (uid, email, created_by, modified_by) VALUES ( $1, $2, $3, $4 )",
    params = list(
      user_uid,
      email,
      user_uid,
      user_uid
    )
  )

  dbExecute(
    conn,
    "INSERT INTO polished.apps (app_name, created_by, modified_by) VALUES ( $1, $2, $3 )",
    params = list(
      app_name,
      user_uid,
      user_uid
    )
  )

  dbExecute(
    conn,
    "INSERT INTO polished.app_users (uid, app_name, user_uid, is_admin, created_by, modified_by) VALUES ( $1, $2, $3, $4, $5, $6 )",
    params = list(
      app_user_uid,
      app_name,
      user_uid,
      TRUE,
      user_uid,
      user_uid
    )
  )
}
