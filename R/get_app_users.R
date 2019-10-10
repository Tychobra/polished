#' get_app_users
#'
#' @param conn the database connection
#' @param app_name the name of the app
#'
#' @return a data frame of the app users from the polished schema.
#'
#' @export
#'
#' @importFrom dplyr tbl filter select collect left_join arrange
#' @importFrom dbplyr in_schema
#' @importFrom rlang !! enquo
#'
get_app_users <- function(conn, app_name) {
  hold_app_name <- rlang::enquo(app_name)

  # find all users of the app
  app_users <- conn %>%
    dplyr::tbl(dbplyr::in_schema("polished", "app_users")) %>%
    dplyr::filter(app_name == !!app_name) %>%
    dplyr::select(
      app_uid = uid,
      app_name,
      user_uid,
      is_admin,
      last_sign_in_at,
      created_at) %>%
    dplyr::collect()

  app_user_uids <- app_users$user_uid

  # find the email address for all users of the app
  app_user_emails <- conn %>%
    dplyr::tbl(dbplyr::in_schema("polished", "users")) %>%
    dplyr::filter(.data$uid %in% app_user_uids) %>%
    dplyr::select(user_uid = .data$uid, .data$email) %>%
    dplyr::collect()

  app_users %>%
    dplyr::left_join(app_user_emails, by = "user_uid") %>%
    dplyr::arrange(desc(.data$last_sign_in_at))
}