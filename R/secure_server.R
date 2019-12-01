#' secure_server
#'
#' @param server A Shiny server function (e.g `function(input, output, session) {}`)
#' @param custom_admin_server Either NULL, the default, or a Shiny server function containing your custom admin
#' server functionality.
#'
#' @export
#'
#' @importFrom shiny observeEvent getQueryString callModule
#'
#' @return session session object with new reactive session$userData$current_user which
#' is set to NULL if user is not signed in or a list with user data if the user is
#' signed in
#'
secure_server <- function(
  server,
  custom_admin_server = NULL
) {


  function(input, output, session) {
    session$userData$user <- reactiveVal(NULL)

    shiny::observeEvent(input$polished__session, {
      polished__session <- input$polished__session

      global_user <- .global_sessions$find(polished__session)

      if (is.null(global_user)) {
        session$userData$user(NULL)
        return()
      } else {


        if (isTRUE(global_user$email_verified)) {

          session$sendCustomMessage(
            "polish__remove_loading",
            message = list()
          )


          if (is.na(global_user$signed_in_as)) {
            session$userData$user(global_user[c("uid", "email", "is_admin", "roles", "token")])
          } else {
            signed_in_as_user <- .global_sessions$get_signed_in_as_user(global_user$signed_in_as)
            signed_in_as_user$token <- global_user$token
            session$userData$user(signed_in_as_user)
          }


        } else {
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


    }, ignoreNULL = TRUE)





    # if the user is an admin and on the admin page, set up the admin server
    shiny::observeEvent(session$userData$user(), {

      query_list <- shiny::getQueryString()
      is_on_admin_page <- if (!is.null(query_list$admin_pane) && query_list$admin_pane == 'true') TRUE else FALSE


      if (isTRUE(session$userData$user()$is_admin) && isTRUE(is_on_admin_page)) {
        callModule(
          admin_module,
          "admin"
        )

        # custom admin server functionality
        if (isTRUE(!is.null(custom_admin_server))) {
          custom_admin_server(input, output, session)
        }
      }

    })

    # go to admin panel
    shiny::callModule(
      admin_button,
      "polished"
    )


    shiny::observeEvent(session$userData$user(), {

      if (is.null(session$userData$user())) {
        shiny::callModule(
          sign_in_module,
          "sign_in"
        )
      }

    }, ignoreNULL = FALSE)



    # custom app server.  Requires signed in user to access
    shiny::observeEvent(session$userData$user(), {
      query_string <- shiny::getQueryString()

      # log session to database "sessions" table
      .global_sessions$log_session(global_user$token, global_user$uid)

      if (is.null(query_string$admin_panel)) {
        server(input, output, session)
      }
    })

  }

}
