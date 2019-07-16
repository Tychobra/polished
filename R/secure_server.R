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


  print(list("users" = .global_users$users))
  session$userData$current_user <- reactiveVal(NULL)

  shiny::observeEvent(input$polish__sign_in, {
    token <- input$polish__sign_in$token
    uid <- input$polish__sign_in$uid
    polished_session <- input$polish__sign_in$session
    print(list(polished_session = polished_session))
    global_user <- .global_users$find_user_by_uid(uid, polished_session)



    if (is.null(global_user)) {

      session$sendCustomMessage(
        "polish__show_loading",
        message = list(
          text = "Loading..."
        )
      )

      # attempt to sign in
      new_user <- NULL


      tryCatch({
        new_user <- User$new(
          firebase_functions_url = firebase_functions_url,
          firebase_auth_token = token,
          app_name = app_name,
          polished_session = polished_session
        )

      }, error = function(error) {
        print(paste0("eror signing in: ", error))
      })

      if (is.null(new_user)) {

        # user sign in failed.
        print("Conditional Option 1")

        session$sendCustomMessage(
          "polish__remove_loading",
          message = list()
        )

        # some type of error occured with sign in, so sign out,
        # and go to sign in page.
        tryCatch({
          sign_out_from_shiny(session, uid)
        }, error = function(error) {
          print("secure_server sign out error")
          print(error)
        })


      } else {
        print("Conditional Option 2")
        # go to app.  If user is admin, then they will have the blue "Admin Panel" button
        # in the bottom right
        .global_users$add_user(new_user)

        session$reload()
      }


    } else {

      # user is already signed in, so we don't need to do anything
      # user was already found in the global scope

      if (isTRUE(global_user$get_email_verified())) {

        print("conditional option 3")
        session$sendCustomMessage(
          "polish__remove_loading",
          message = list()
        )

        signed_in_as <- global_user$get_signed_in_as()

        if (!is.null(signed_in_as) && isTRUE(global_user$get_is_admin())) {

          user_out <- signed_in_as[c("email", "is_admin", "role")]

        } else {
          user_out <- list(
            "email" = global_user$get_email(),
            "is_admin" = global_user$get_is_admin(),
            "role" = global_user$get_role()
          )
        }

        user_out$uid <- uid
        user_out$polished_session <- polished_session

        session$userData$current_user(user_out)

      } else {
        print("conditional option 4")
        # go to email verification view.
        # `secure_ui()` will go to email verification view if isTRUE(is_authed) && isFALSE(email_verified)
        #print("email verification sign_in_with_token")

        global_user$refreshEmailVerification()


        # if refreshing the email verification causes it to switch from FALSE to TRUE
        # then reload the session, and the user will move from the email verification page
        # to the actual app
        if (isTRUE(global_user$get_email_verified())) {
          session$reload()
        }


      }

      return()
    }
  }, ignoreInit = TRUE)




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

    session$sendCustomMessage(
      "polish__show_loading",
      message = list(
        text = "Loading..."
      )
    )

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
