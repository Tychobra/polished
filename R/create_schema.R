#' create_schema
#'
#' create all the tables in the "polished" schema.  The "polished" schema contains the following tables.
#'  - users
#'  - apps
#'  - app_users
#'  - sessions
#'  - session_actions
#'
#' @param conn the `RPostgres` database connection.  Only `RPostgres` is supported.
#'
#' @importFrom DBI dbExecute
#'
#' @export
#'
#'
create_schema <- function(conn) {

  # For UUID generate
  DBI::dbExecute(conn, 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')
  # for encryption
  DBI::dbExecute(conn, 'CREATE EXTENSION IF NOT EXISTS pgcrypto;')

  create_accounts_table_query <- "CREATE TABLE polished.accounts (
    uid                            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email                          TEXT,
    polished_key                   TEXT,
    hashed_polished_key            TEXT,
    created_at                     TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )"

  create_users_table_query <- "CREATE TABLE polished.users (
    uid                            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_uid                    UUID REFERENCES polished.accounts(uid),
    email                          TEXT,
    created_by                     TEXT NOT NULL,
    created_at                     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by                    TEXT NOT NULL,
    modified_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_uid, email)
  )"


  create_apps_table_query <- "CREATE TABLE polished.apps (
    uid                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_uid           UUID REFERENCES polished.accounts(uid),
    app_name              TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_uid, app_name)
  )"

  create_app_users_table_query <- "CREATE TABLE polished.app_users (
    uid                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_uid           UUID REFERENCES polished.accounts(uid),
    app_uid               UUID REFERENCES polished.apps(uid) ON DELETE CASCADE,
    user_uid              UUID REFERENCES polished.users(uid) ON DELETE CASCADE,
    is_admin              BOOLEAN NOT NULL,
    created_by            TEXT NOT NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by           TEXT NOT NULL,
    modified_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_uid, app_uid, user_uid)
  )"


  create_sessions_table_query <- "CREATE TABLE polished.sessions (
    uid                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_uid           UUID REFERENCES polished.accounts(uid),
    user_uid              UUID REFERENCES polished.users(uid),
    email                 TEXT,
    email_verified        BOOLEAN,
    hashed_cookie         TEXT,
    signed_in_as          TEXT,
    app_uid               TEXT,
    is_active             BOOLEAN DEFAULT true,
    is_signed_in          BOOLEAN DEFAULT true,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )"

  # create_session_actions_table_query <- "CREATE TABLE polished.session_actions (
  #   uid                  TEXT PRIMARY KEY,
  #   session_uid          TEXT,
  #   action               TEXT,
  #   timestamp            TIMESTAMPTZ NOT NULL DEFAULT NOW()
  # )"



  DBI::dbExecute(conn, "CREATE SCHEMA IF NOT EXISTS polished")
  DBI::dbExecute(conn, "DROP TABLE IF EXISTS polished.accounts CASCADE")
  DBI::dbExecute(conn, "DROP TABLE IF EXISTS polished.users CASCADE")
  DBI::dbExecute(conn, "DROP TABLE IF EXISTS polished.apps CASCADE")
  DBI::dbExecute(conn, "DROP TABLE IF EXISTS polished.app_users CASCADE")
  DBI::dbExecute(conn, "DROP TABLE IF EXISTS polished.sessions")
  #dbExecute(conn, "DROP TABLE IF EXISTS polished.session_actions")

  DBI::dbExecute(conn, create_accounts_table_query)
  DBI::dbExecute(conn, create_users_table_query)
  DBI::dbExecute(conn, create_apps_table_query)
  DBI::dbExecute(conn, create_app_users_table_query)
  DBI::dbExecute(conn, create_sessions_table_query)
  #dbExecute(conn, create_session_actions_table_query)

}
