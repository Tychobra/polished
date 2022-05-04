#' Secure your Shiny app's server
#'
#' This function is used to secure your Shiny app's server function.  Make sure to pass
#' your Shiny app's server function as the first argument to \code{secure_server()} at
#' the bottom of your Shiny app's \code{server.R} file.
#'
#' @param server A Shiny server function (e.g \code{function(input, output, session) {}})
#' @param custom_admin_server Either \code{NULL}, the default, or a Shiny server function containing your custom admin
#' server functionality.
#' @param custom_sign_in_server Either \code{NULL}, the default, or a Shiny server containing your custom
#' sign in server logic.
#'
#' @export
#'
#' @importFrom shiny observe observeEvent getQueryString updateQueryString callModule onStop reactiveVal req
#' @importFrom digest digest
#'
#'
secure_server <- function(
  server,
  custom_sign_in_server = NULL,
  custom_admin_server = NULL
) {

  server <- force(server)

  if (!exists(".polished")) {
    stop("`.polished` does not exists.  Configure it with `polished_config()`", call. = FALSE)
  }

  function(input, output, session) {
    session$userData$user <- function() NULL
    session$userData$p <- NULL


    # handle the initial input$hashed_cookie
    shiny::observeEvent(input$hashed_cookie, {
      hashed_cookie <- input$hashed_cookie

      global_user <- NULL
      if (isTRUE(.polished$admin_mode)) {
        global_user <- list(
          session_uid = uuid::UUIDgenerate(),
          user_uid = "00000000-0000-0000-0000-000000000000",
          email = "admin@tychobra.com",
          is_admin = TRUE,
          hashed_cookie = character(0),
          email_verified = TRUE,
          roles = NA,
          two_fa_verified = TRUE
        )

        shiny::updateQueryString(
          queryString = paste0("?page=admin"),
          session = session,
          mode = "push"
        )

        if (is.null(custom_admin_server)) {

          admin_server(input, output, session)

        } else {

          custom_admin_server(input, output, session)

        }

        return(NULL)
      }

      # attempt to find the signed in user.  If user is signed in, `global_user`
      # will be a list of user data.  If the user is not signed in, `global_user`
      # will be `NULL`
      query_list <- shiny::getQueryString()
      page <- query_list$page


      if (is.character(hashed_cookie) && identical(nchar(hashed_cookie), 32L)) {
        tryCatch({
          global_user_res <- get_sessions(
            app_uid = .polished$app_uid,
            hashed_cookie = hashed_cookie,
            session_started = if (is.null(page)) TRUE else FALSE
          )

          global_user <- global_user_res$content

        }, error = function(err) {
          print("secure_server: unable to get session")
          print(err)
          invisible(NULL)
        })
      }


      if (is.null(global_user)) {
        # user is not signed in

        # if the user is not on the sign in page, redirect to sign in and reload
        if (isTRUE(.polished$is_auth_required)) {
          if (!identical(page, "sign_in")) {
            shiny::updateQueryString(
              queryString = paste0("?page=sign_in"),
              session = session,
              mode = "replace"
            )
            session$reload()
          } else {
            # load up the sign in server
            if (is.null(custom_sign_in_server)) {

              sign_in_module(input, output, session)

            } else {

              custom_sign_in_server(input, output, session)

            }
          }
        } else {

          if (identical(page, "sign_in")) {
            if (is.null(custom_sign_in_server)) {

              sign_in_module(input, output, session)

            } else {

              custom_sign_in_server(input, output, session)

            }
          } else {

            # go to the custom app
            server(input, output, session)
          }
        }

      } else {
        # the user is signed in

        if (isFALSE(global_user$email_verified) && isTRUE(.polished$is_email_verification_required)) {
          # go to email verification view.
          # `secure_ui()` will go to email verification view if isTRUE(is_authed) && isFALSE(email_verified)
          verify_email_server(input, output, session)

        } else {


          # if the user somehow ends up on the sign_in page, redirect them to the
          # Shiny app and reload
          if (identical(query_list$page, "sign_in")) {
            remove_query_string()
            session$reload()
          }

          if (is.na(global_user$signed_in_as) || identical(query_list$page, "admin")) {

            # user is not on the custom Shiny app, so clear the signed in as user
            if (!is.na(global_user$signed_in_as)) {
              # clear signed in as in .polished
              update_session(
                session_uid = global_user$session_uid,
                session_data = list(
                  signed_in_as = NA
                )
              )
            }

            user_out <- global_user[
              c("session_uid", "user_uid", "email", "is_admin", "hashed_cookie", "email_verified", "roles", "two_fa_verified")
            ]

            session$userData$user <- function() user_out
            session$userData$p <- user_out

          } else {

            signed_in_as_user <- get_signed_in_as_user(global_user$signed_in_as)
            signed_in_as_user$session_uid <- global_user$session_uid
            signed_in_as_user$hashed_cookie <- global_user$hashed_cookie

            # set email verified to TRUE, so that you go directly to app
            signed_in_as_user$email_verified <- global_user$email_verified
            signed_in_as_user$two_fa_verified <- global_user$two_fa_verified
            session$userData$user <- function() signed_in_as_user
            session$userData$p <- signed_in_as_user
          }



          if (.polished$is_two_fa_required && !isTRUE(global_user$two_fa_verified)) {

            two_fa_server(input, output, session)

          } else if (isTRUE(global_user$is_admin) && identical(page, "admin")) {

            if (is.null(custom_admin_server)) {

              admin_server(input, output, session)

            } else {

              custom_admin_server(input, output, session)

            }

          } else {

            # go to the custom app
            server(input, output, session)

            # go to admin panel button.  Must load this whether or not the user is an
            # admin so that if an admin is signed in as a non admin, they can still
            # click the button to return to the admin panel.
            shiny::callModule(
              admin_button,
              "polished"
            )

            # set the session to inactive when the session ends
            shiny::onStop(fun = function() {

              tryCatch({

                update_session(
                  session_uid = global_user$session_uid,
                  session_data = list(
                    is_active = FALSE
                  )
                )

              }, catch = function(err) {
                print('error setting the session to incative')
                print(err)
              })

            })


          }

        }
      }


    }, ignoreNULL = TRUE)

  }

}
