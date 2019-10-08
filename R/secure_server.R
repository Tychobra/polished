#' secure_server
#'
#' @param server A Shiny server function (e.g `function(input, output, session) {}`)
#' @param conn database connection
#' @param custom_admin_server Either NULL, the default, or a Shiny server function containing your custom admin
#' server functionality.
#'
#' @export
#'
#'
#' @return session session object with new reactive session$userData$current_user which
#' is set to NULL if user is not signed in or a list with user data if the user is
#' signed in
#'
secure_server <- function(
  server,
  conn,
  custom_admin_server = NULL
) {


  function(input, output, session) {
    session$userData$user <- reactiveVal(NULL)
    session$userData$pcon <- conn

    shiny::observeEvent(input$polished__sign_in, {
      firebase_token <- input$polished__sign_in$firebase_token
      polished_token <- input$polished__sign_in$polished_token


      # the user session
      global_user <- NULL

      if (!is.null(polished_token)) {
        # token already exists in cookie, so see if there is a corresponding session on server side
        global_user <- .global_sessions$find(polished_token)
      }


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
          new_user <- .global_sessions$sign_in(conn, firebase_token)

        }, error = function(error) {
          print(paste0("eror signing in: ", error))
        })

        if (is.null(new_user)) {
          # user sign in failed.

          session$sendCustomMessage(
            "polish__remove_loading",
            message = list()
          )

          # sign out from Firebase on client side
          # sign_out_from_shiny()

          session$sendCustomMessage(
            "polish__show_toast",
            message = list(
              type = "error",
              title = "Error signing into polished server",
              message = NULL
            )
          )

          # some type of error occured with sign in, so sign out,
          # and go to sign in page
          return()

        } else {
          # go to app.  If user is admin, then they will have the blue "Admin Panel" button
          # in the bottom right

          # send cookie to front end, wait for confirmation that cookie is set, and then reload session
          session$sendCustomMessage(
            "polished__set_cookie",
            list(
              polished_token = new_user$token
            )
          )

          observeEvent(input$polished__set_cookie_complete, {
            session$reload()
          }, once = TRUE)

        }

      } else {

        # user is already signed in, so we don't need to do anything
        # user was already found in the global scope
        session$userData$user(global_user)
      }
    }, ignoreInit = TRUE)


    observeEvent(input$polished__session, {

      global_user <- .global_sessions$find(input$polished__session)

      if (is.null(global_user)) {
        session$userData$user(NULL)
        return()
      } else {


        if (isTRUE(global_user$email_verified)) {

          session$sendCustomMessage(
            "polish__remove_loading",
            message = list()
          )

          # log session to database "sessions" table
          .global_sessions$log_session(conn, global_user$token, global_user$uid)

          session$userData$user(global_user)

        } else {
          print("secure_server 4")
          # go to email verification view.
          # `secure_ui()` will go to email verification view if isTRUE(is_authed) && isFALSE(email_verified)

          token <- global_user$token
          global_user <- .global_sessions$refresh_email_verification(
            token,
            global_user$firebase_uid
          )$find(token)


          # if refreshing the email verification causes it to switch from FALSE to TRUE
          # then reload the session, and the user will move from the email verification page
          # to the actual app
          if (isTRUE(global_user$email_verified)) {
            session$reload()
          }
        }
      }


    })





    # if the user is an admin and on the admin page, set up the admin server
    observeEvent(session$userData$user(), {

      query_list <- shiny::getQueryString()
      is_on_admin_page <- if (!is.null(query_list$admin_pane) && query_list$admin_pane == 'true') TRUE else FALSE


      if (isTRUE(session$userData$user()$is_admin) && isTRUE(is_on_admin_page)) {
        callModule(
          admin_module,
          "admin"
        )
      }

    })

    # go to admin panel
    callModule(
      admin_button,
      "polished"
    )


    # custom admin server functionality
    if (isTRUE(!is.null(custom_admin_server))) {
      observeEvent(session$userData$user(), {
        custom_admin_server(input, output, session)
      })
    }

    observeEvent(session$userData$user(), {

      if (is.null(session$userData$user())) {
        callModule(
          sign_in_module,
          "sign_in",
          conn
        )
      }

    }, ignoreNULL = FALSE)



    # user developed server.  Required signed in user to
    # access
    observeEvent(session$userData$user(), {
      query_string <- getQueryString()

      if (is.null(query_string$admin_panel)) {
        server(input, output, session)
      }
    })

  }

}
