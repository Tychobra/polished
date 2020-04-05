
#' get active users
#'
#' @param conn the database connection
#' @param app_uid_ the app id
#' @param schema the name of the schema
#'
#' @importFrom dbplyr in_schema
#' @importFrom dplyr tbl filter distinct collect
#'
#' @export
#'
#'
get_active_users <- function(conn, app_uid_, schema = "polished") {

  conn %>%
    dplyr::tbl(dbplyr::in_schema(schema, "sessions")) %>%
    dplyr::filter(
      .data$app_uid == app_uid_,
      .data$is_active == TRUE
    ) %>%
    dplyr::distinct(.data$email) %>%
    dplyr::collect()
}
