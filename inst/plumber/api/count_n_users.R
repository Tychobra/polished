


count_n_users <- function(conn, account_uid) {

  DBI::dbGetQuery(
    conn,
    "SELECT COUNT(uid) FROM public.users WHERE created_by=$1",
    params = list(
      account_uid
    )
  )$count
}
