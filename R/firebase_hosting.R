#' generate firebase hosting text
#'
#' This text is used as configuration in firebase.json
#'
#' @param app_names the names of all apps using Firebase hosting
#'
#' @export
#'
#' @examples
#'
#' generate_firebase_hosting_text("shiny_1")
#'
#' generate_firebase_hosting_text(c("shiny_1", "shiny_2"))
#'
generate_firebase_hosting_text <- function(app_names) {

  n_apps <- length(app_names)

  hosted_apps_config <- unlist(lapply(seq_along(app_names), function(i) {

    last_paren <- '    }'
    if (i != n_apps) {
      last_paren <- paste0(last_paren, ',')
    }

    c(
      '    {',
      paste0('      "target": "', app_names[i], '",'),
      paste0('      "public": "hosting/', app_names[i], '",'),
      '      "ignore": [',
      '        "firebase.json",',
      '        "**/.*",',
      '        "**/node_modules/**"',
      '      ]',
      last_paren
    )
  }))


  c(
    '{',
    '  "firestore": {',
    '    "rules": "firestore.rules",',
    '    "indexes": "firestore.indexes.json"',
    '  },',
    '  "hosting": [',
    hosted_apps_config,
    '  ]',
    '}'
  )
}

#' write firebase hosting configuration to firebase.json
#'
#'
#' @param app_names The name(s) of the apps used
#' @param file_path The path of the firebase hosting configuration file
#'
#' @export
#'
#' @examples
#'
#' write_firebase_hosting("shiny_app_1")
#'
#' write_firebase_hosting(c("shiny_app_1", "shiny_app_2"))
#'
write_firebase_hosting <- function(app_names, file_path = "firebase.json") {

  hosting_text <- generate_firebase_hosting_text(app_names)

  file_conn <- file(file_path)
  on.exit(close(file_conn), add = TRUE)

  writeLines(
    hosting_text,
    file_conn,
  )
}
