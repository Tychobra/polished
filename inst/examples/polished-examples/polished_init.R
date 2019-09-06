library(polished)

app_names <- c(
  "auth_basic",
  "auth_custom",
  "custom_admin_tabs"
)

write_firestore_rules(app_names)

polished::write_firebase_functions()


# TODO: make polished `firebase_deploy()` to handle deployment
system("firebase deploy --only firestore:rules")
system("firebase deploy --only functions")

# write firebase hosting configuration
#write_firebase_hosting(app_names)
# write firebase hosting html
#write_firebase_hosting_html(app_names)

# TODO: `firebase_deploy()` also needs to handle this part of deployment
#system("firebase target:apply hosting claims_portal polished-rhodes")
#system("firebase deploy --only hosting:claims_portal")
#polished::write_firestore_rules(
#  c("pc-exposure-bessemer")
#)
