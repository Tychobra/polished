#' get_app_users
#'
#' @param conn the database connection
#' @param app_uid the id of the app
#' @param schema the database schema
#'
#' @return a data frame of the app users from the polished schema.
#'
#' @export
#'
#' @importFrom dplyr tbl filter select collect left_join arrange .data
#' @importFrom dbplyr in_schema
#' @importFrom rlang .env
#'
get_app_users <- function(conn, app_uid, schema = "polished") {

  # find all users of the app
  app_users <- conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "app_users")) %>%
    dplyr::filter(.data$app_uid == .env$app_uid) %>%
    dplyr::select(
      .data$uid,
      .data$app_uid,
      .data$user_uid,
      .data$is_admin,
      .data$created_at) %>%
    dplyr::collect()

  app_user_uids <- app_users$user_uid

  # find the email address for all users of the app
  app_user_emails <- conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "users")) %>%
    dplyr::filter(.data$uid %in% app_user_uids) %>%
    dplyr::select(user_uid = .data$uid, .data$email) %>%
    dplyr::collect()

  app_users %>%
    dplyr::left_join(app_user_emails, by = "user_uid")
}