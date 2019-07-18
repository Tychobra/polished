#' generate firestore rules text
#'
#' This text will be used to write the firestore.rules file
#'
#' @param app_names the names of all apps using firebase hosting
#'
#' @export
#'
#' @example
#'
#' generate_firestore_rules_text("shiny_1")
#'
#' generate_firestore_rules_text("shiny_1, shiny_2")
#'
generate_firestore_rules_text <- function(app_names) {
  matches <- unlist(lapply(app_names, function(name) {
    c(
      paste0("    match /apps/", name, "/users/{email} {"),
      "",
      "      allow read: if true;",
      "",
      paste0('      allow write: if request.auth.token.email == email || is_admin(database, request.auth.token.email, "', name, '");'),
      "    }",
      "",
      paste0("    match /apps/", name, "/roles/{role} {"),
      "",
      "      allow read: if request.auth.uid != null;",
      "",
      paste0('      allow write: if request.auth.uid != null && is_admin(database, request.auth.token.email, "', name, '");'),
      "    }",
      "",
      paste0("    match /apps/", name, "/sessions/{session} {"),
      "",
      paste0("      allow read: if is_admin(database, request.auth.token.email, ", name, ");"),
      "",
      "      allow write: if false;",
      "    }",
      ""
    )
  }))

  c(
    "rules_version = '2';",
    "service cloud.firestore {",
    "  match /databases/{database}/documents {",
    "",
    "    function is_admin (database, email, app_name) {",
    '      return get(path("/databases/" + database + "/documents/apps/" + app_name + "/users/" + email)).data.is_admin;',
    "    }",
    "",
    matches,
    "",
    "  }",
    "}"
  )
}


#' write the firestore.rules file
#'
#'
#' @param app_names The name(s) of the apps used
#' @param dir The directory for firestore.rules
#' @param file_name The name of the new file
#'
#' @export
#'
#' @examples
#'
#' write_firestore_rules("project1")
#'
#' write_firestore_rules(c("project1", "project2"), "R", "file.rules")
#'
write_firestore_rules <- function(app_names, dir = ".", file_name = "firestore.rules") {

  rules_text <- generate_firestore_rules_text(app_names)

  file_conn <- file(file.path(dir, file_name))
  on.exit(close(file_conn), add = TRUE)

  writeLines(
    rules_text,
    file_conn
  )
}

