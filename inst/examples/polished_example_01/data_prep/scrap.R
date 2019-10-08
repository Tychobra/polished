library(dplyr)
library(dbplyr)

db_config <- config::get(file = "shiny_app/config.yml")$db
conn <- tychobratools::db_connect(db_config)

# find all users of the app
app_users <- conn %>%
  tbl(in_schema("polished", "app_users")) %>%
  filter(app_name == "polished_example_01") %>%
  select(app_uid = uid, app_name, user_uid, is_admin, created_at) %>%
  collect()


app_user_uids <- app_users$user_uid
# find the email address for all users of the app
app_user_emails <- conn %>%
  tbl(in_schema("polished", "users")) %>%
  filter(uid %in% app_user_uids) %>%
  select(user_uid = uid, email) %>%
  collect()

out <- app_users %>%
  left_join(app_user_emails, by = "user_uid")



dbDisconnect(conn)
