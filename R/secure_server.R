#' secure_server
#'
#' @param server A Shiny server function (e.g `function(input, output, session) {}`)
#' @param custom_admin_server Either NULL, the default, or a Shiny server function containing your custom admin
#' server functionality.
#' @param allow_reconnect argument to pass to Shiny's `session$allowReconnect()` function. Defaults to
#' `FALSE`.  Set to `TRUE` to allow reconnect with shiny-server and Rstudio Connect.  Set to "force"
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
  allow_reconnect = FALSE
) {


  function(input, output, session) {
    session$userData$user <- reactiveVal(NULL)

    if (isTRUE(allow_reconnect) || allow_reconnect == "force") {
      session$allowReconnect(allow_reconnect)
    }


    # handle the initial input$polished_session
    shiny::observeEvent(input$polished__session, {
      polished__session <- input$polished__session

      # attempt to find the signed in user.  If user is signed in, `global_user`
      # will be a list of user data.  If the user is not signed in, `global_user`
      # will be `NULL`
      global_user <- .global_sessions$find(polished__session)
      query_list <- shiny::getQueryString(session)

      if (is.null(global_user)) {
        # user is not signed in

        # if the user is not on the sign in page, redirect to sign in and reload
        if (is.null(query_list$page) || query_list$page != "sign_in") {
          shiny::updateQueryString(
            queryString = paste0("?page=sign_in"),
            session = session,
            mode = "replace"
          )
          session$reload()
        } else {

          session$userData$user(NULL)
          return()
        }



      } else {
        # the user is signed in

        # if the user somehow ends up on the sign_in page, redirect them to the
        # Shiny app and reload
        if (!is.null(query_list$page) && query_list$page == "sign_in") {
          remove_query_string()
          session$reload()
        }

        #if (isTRUE(global_user$email_verified)) {
        if (is.na(global_user$signed_in_as)) {

          user_out <- global_user[
            c("session_uid", "user_uid", "email", "is_admin", "roles", "token", "email_verified")
          ]

          session$userData$user(user_out)

        } else {
          signed_in_as_user <- .global_sessions$get_signed_in_as_user(global_user$signed_in_as)
          signed_in_as_user$session_uid <- global_user$session_uid
          signed_in_as_user$token <- global_user$token

          # set email verified to TRUE, so that you go directly to app
          signed_in_as_user$email_verified <- TRUE
          session$userData$user(signed_in_as_user)
        }
      }


    }, ignoreNULL = TRUE)





    # if the user is an admin and on the admin page, set up the admin server
    shiny::observeEvent(session$userData$user(), {

      if (isTRUE(session$userData$user()$email_verified)) {
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

      } else {

        # go to email verification view.
        # `secure_ui()` will go to email verification view if isTRUE(is_authed) && isFALSE(email_verified)

        callModule(
          verify_email_module,
          "verify"
        )
        #tryCatch({
        #   global_user <- .global_sessions$refresh_email_verification(
        #     global_user$session_uid,
        #     global_user$firebase_uid
        #   )$find(token)
        # }, error = function(err) {
        #   # set query string to sign in page
        #
        #   sign_out_from_shiny(
        #     session,
        #     user = list(
        #       user_uid = global_user$user_uid,
        #       session_uid = global_user$session_uid
        #     )
        #   )
        #
        #   print("[polished] error - refreshing email verification")
        #   session$reload()
        # })
      }



    })

    # go to admin panel
    shiny::callModule(
      admin_button,
      "polished"
    )

    shiny::callModule(
      sign_in_module,
      "sign_in"
    )



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
