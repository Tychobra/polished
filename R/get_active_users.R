
#' get active users
#'
#' @param conn the database connection
#' @param app_uid the app id
#' @param schema the name of the schema
#'
#' @importFrom dbplyr in_schema
#' @importFrom dplyr tbl filter distinct collect
#' @importFrom rlang .env
#'
#' @export
#'
#'
get_active_users <- function(conn, app_uid, schema = "polished") {

  conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "sessions")) %>%
    dplyr::filter(
      .data$app_uid == .env$app_uid,
      .data$is_active == TRUE
    ) %>%
    dplyr::distinct(.data$email) %>%
    dplyr::collect()
}
