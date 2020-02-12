#' secure_server
#'
#' @param server A Shiny server function (e.g `function(input, output, session) {}`)
#' @param custom_admin_server Either NULL, the default, or a Shiny server function containing your custom admin
#' server functionality.
#' @param allow_reconnect argument to pass to Shiny's `session$allowReconnect()` function. Defaults to
#' `NULL`.  Set to `TRUE` to allow reconnect with shiny-server and Rstudio Connect.  Set to "force"
#' for local testing.  See \link{https://shiny.rstudio.com/articles/reconnecting.html} for more information.
#'
#' @export
#'
#' @importFrom shiny observeEvent getQueryString callModule
#' @importFrom digest digest
#'
#' @return session session object with new reactive session$userData$current_user which
#' is set to NULL if user is not signed in or a list with user data if the user is
#' signed in
#'
secure_server <- function(
  server,
  custom_admin_server = NULL,
  allow_reconnect = NULL
) {


  function(input, output, session) {
    session$userData$user <- reactiveVal(NULL)

    if (isTRUE(allow_reconnect) || allow_reconnect == "force") {
      session$allowReconnect(allow_reconnect)
    }


    # track the polished in a non reactive, so that we can access it in
    # the onStop() funtion
    #non_rv_token <- NULL

    shiny::observeEvent(input$polished__session, {
      polished__session <- input$polished__session

      global_user <- .global_sessions$find(polished__session)

      if (is.null(global_user)) {
        session$userData$user(NULL)
        return()
      } else {



        if (isTRUE(global_user$email_verified)) {



          if (is.na(global_user$signed_in_as)) {
            session$userData$user(global_user[c("session_uid", "user_uid", "email", "is_admin", "roles", "token")])


          } else {
            signed_in_as_user <- .global_sessions$get_signed_in_as_user(global_user$signed_in_as)
            signed_in_as_user$session_uid <- global_user$session_uid
            signed_in_as_user$token <- global_user$token
            session$userData$user(signed_in_as_user)
          }


        } else {
          # go to email verification view.
          # `secure_ui()` will go to email verification view if isTRUE(is_authed) && isFALSE(email_verified)

          token <- global_user$token
          global_user <- .global_sessions$refresh_email_verification(
            global_user$session_uid,
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
      is_on_admin_page <- if (!is.null(query_list$page) && query_list$page == 'admin_panel') TRUE else FALSE


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

      if (is.null(query_string$page)) {
        session_uid <- session$userData$user()$session_uid
        server(input, output, session)

        # set the session from inactive to active
        .global_sessions$set_active(session_uid)

        # set the session to inactive when the session ends
        shiny::onStop(fun = function() {

          tryCatch({

            .global_sessions$set_inactive(session_uid)

          }, catch = function(err) {
            print('error setting the session to incative')
            print(err)
          })

        })
      }
    })



  }

}
