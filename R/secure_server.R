#' secure_server
#'
#' @param input input argument from shiny server
#' @param session session argument from shiny server
#' @param firebase_function_url url for the firebase function to sign in
#' @param dev_user list defining the user to sign in as during development
#'
#'
#' @export
#'
#' @return session session object with new reactive session$userData$current_user which
#' is set to NULL if user is not signed in or a list with user data if the user is
#' signed in
#'
secure_server <- function(input, session, firebase_function_url, app_name, dev_user = list(
  email = "andy.merlino@tychobra.com",
  is_admin = TRUE,
  role = ""
)) {

  session$userData$current_user <- reactiveVal(NULL)

  polish_sign_out <- function(token) {
    # TODO: create this method
    #global_users$remove_user(token)


  }

  shiny::observeEvent(input$polish__token, {
    token <- input$polish__token

    # If token is set then the user is already signed in and we don't need to do anything.
    # if it is not set then we need to set it and reload the session
    query_token <- parseQueryString(session$clientData$url_search)$token

    user <- .global_users$find_user_by_token(token)
    #print(list())
    #print(list("token" = token))
    # if the user == NULL i.e. user has not yet been added to `global_users`, so create a new user here
    #print(list("user_by_token" = user))

    #print(list("query_token" = query_token))
    #print(list("token" = token))
    #print(list("identical" = identical(query_token, token)))

    if (!is.null(query_token)) {
      #print("identical token and query_token")
      if (is.null(user)) {
        print("conditional option 1")
        # this should not happen, TODO: trigger sign out
        session$reload()
        return()
      } else {
        # user is already signed in, so we don't need to do anything
        # user was already found in the global scope
        if (isTRUE(user$get_email_verified())) {

          print("conditional option 2")
          user_out <- list(
            "email" = user$get_email(),
            "is_admin" = user$get_is_admin(),
            "role" = user$get_role()
          )
          # set the signed in user to the session$userData
          session$userData$current_user(user_out)
        } else {
          print("conditional option 3")
          # go to email verification view.
          # `secure_ui()` will go to email verification view if isTRUE(is_authed) && isFALSE(email_verified)
          print(list("email verification sign_in_with_token"))

          # TODO: create a firebase function to check if the email has been verified
          # this function should be callable by a method to the `User` class
          user$refreshEmailVerification()

          # if refreshing the email verification causes it to switch from FALSE to TRUE
          # then reload the session, so the user can move on from the email verification page
          # to the actual app
          #if (isTRUE(user$get_email_verification())) {
          #  session$reload()
          #}

          return()
        }

      }

    } else {

      if (is.null(user)) {
        # attempt to sign the user in
        tryCatch({
          user <- User$new(
            firebase_function_url = firebase_function_url,
            firebase_auth_token = token,
            app_name = app_name
          )

        }, error = function(error) {
          print(paste0("eror signing in: ", error))
        })
      }

      # if the user sign in fails, user will still == NULL, so check
      # user, and sign out id user == NULL
      if (is.null(user)) {
        print("conditional option 4")
        session$sendCustomMessage(
          "remove_loading",
          message = list()
        )
        # TODO: trigger sign out display not authorized message

        #session$reload()

        return()
      } else {
        print("conditional option 5")
        # user successfully signed in, so set the user in the global scope
        .global_users$add_user(user)

        updateQueryString(
          queryString = sprintf("?token=%s", token),
          session = session,
          mode = "replace"
        )

        session$userData$current_user(list(
          "email" = user$get_email(),
          "is_admin" = user$get_is_admin(),
          "role" = user$get_role()
        ))

        session$reload()

      }

    }

  })

  observeEvent(input$polish__sign_out, {

    sign_out_from_shiny(session)

  })

  # if the user is signed in, set up the polish firebase functions
  observeEvent(session$userData$current_user(), {

    callModule(
      admin_module,
      "admin"
    )

    callModule(
      verify_email,
      "verify"
    )
  })

  observeEvent(input$polish__go_to_admin_panel, {

    query_token <- parseQueryString(session$clientData$url_search)$token

    # remove admin_pane=false from query
    updateQueryString(
      queryString = paste0("?token=", query_token),
      session = session,
      mode = "replace"
    )

    session$reload()
  }, ignoreInit = TRUE)



  session
}
