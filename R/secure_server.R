#' secure_server
#'
#' @param input input argument from shiny server
#' @param session session argument from shiny server
#' @param firebase_functions_url url for the firebase function to sign in
#'
#'
#' @export
#'
#' @return session session object with new reactive session$userData$current_user which
#' is set to NULL if user is not signed in or a list with user data if the user is
#' signed in
#'
secure_server <- function(input, session, firebase_functions_url, app_name) {

  session$userData$current_user <- reactiveVal(NULL)

  shiny::observeEvent(input$polish__sign_in, {
    token <- input$polish__sign_in$token
    uid <- input$polish__sign_in$uid

    user <- .global_users$find_user_by_uid(uid)

    if (is.null(user)) {

      # attempt to sign in
      new_user <- NULL
      tryCatch({
        new_user <- User$new(
          firebase_functions_url = firebase_functions_url,
          firebase_auth_token = token,
          app_name = app_name
        )

      }, error = function(error) {
        print(paste0("eror signing in: ", error))
      })

      if (is.null(new_user)) {


        sign_out_from_shiny(session, uid)
        print("Not Authorized")
      } else {

        .global_users$add_user(new_user)

        is_admin <- new_user$get_is_admin()

        if (isTRUE(is_admin)) {
          updateQueryString(
            queryString = paste0("?admin_panel=true"),
            session = session,
            mode = "replace"
          )
        }


        session$reload()
      }


    } else {

      # user is already signed in, so we don't need to do anything
      # user was already found in the global scope
      print(list("email_verified" = user$get_email_verified()))
      if (isTRUE(user$get_email_verified())) {

        print("conditional option 2")
        session$userData$current_user(list(
          "email" = user$get_email(),
          "is_admin" = user$get_is_admin(),
          "role" = user$get_role(),
          "uid" = uid
        ))

      } else {
        print("conditional option 3")
        # go to email verification view.
        # `secure_ui()` will go to email verification view if isTRUE(is_authed) && isFALSE(email_verified)
        print("email verification sign_in_with_token")

        user$refreshEmailVerification()


        session$sendCustomMessage(
          "remove_loading",
          message = list()
        )

        # if refreshing the email verification causes it to switch from FALSE to TRUE
        # then reload the session, and the user will move from the email verification page
        # to the actual app
        if (isTRUE(user$get_email_verified())) {
          session$reload()
        }

        return()
      }
    }
  }, ignoreInit = TRUE)

  # shiny::observeEvent(input$polish__token, {
  #   token <- input$polish__token
  #
  #
  #   #user <- .global_users$find_user_by_token(token)
  #   user <- .global_users$find_user_by_id(token)
  #
  #
  # }, ignoreInit = TRUE)


  observeEvent(input$polish__sign_out, {
    req(session$userData$current_user())
    sign_out_from_shiny(session, session$userData$current_user()$uid)
  })

  # if the user is signed in, set up the polish firebase functions
  observeEvent(session$userData$current_user(), {

    callModule(
      admin_module,
      "admin"
    )


  })

  observeEvent(input$polish__go_to_admin_panel, {


    # remove admin_pane=false from query
    updateQueryString(
      queryString = paste0("?admin_panel=true"),
      session = session,
      mode = "replace"
    )

    session$reload()
  }, ignoreInit = TRUE)

  session
}
