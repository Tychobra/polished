#' user_edit_module
#'
#' @param input Shiny server function input
#' @param output Shiny sever function output
#' @param session Shiny server function session
#' @param modal_title the title for the modal
#' @param user_to_edit reactive - a one row data frame of the user to edit from the "app_users" table.
#' @param open_modal_trigger reactive - a trigger to open the modal
#' @param existing_users reactive data frame of all users of this app.  This is used to check that the user
#' does not add a user that already exists.
#'
#' @export
#'
#' @importFrom shiny reactive observeEvent showModal modalDialog modalButton removeModal
#' @importFrom DBI dbExecute dbWithTransaction
#' @importFrom shinyWidgets pickerInput
#' @importFrom tychobratools show_toast
#'
user_edit_module <- function(input, output, session,
  modal_title,
  user_to_edit,
  open_modal_trigger,
  existing_users
) {

  ns <- session$ns


  shiny::observeEvent(open_modal_trigger(), {
    hold_user <- user_to_edit()

    if (is.null(hold_user)) {
      is_admin_value  <- "No"

      email_input <- shiny::textInput(
        ns("user_email"),
        "Email",
        value = if (is.null(hold_user)) "" else hold_user$email
      )

    } else {
      if (isTRUE(hold_user$is_admin)) {
        is_admin_value <- "Yes"
      } else {
        is_admin_value <- "No"
      }

      email_input <- NULL
    }



    shiny::showModal(
      shiny::modalDialog(
        title = modal_title,
        footer = list(
          modalButton("Cancel"),
          actionButton(
            ns("submit"),
            "Submit",
            class = "btn-success",
            icon = icon("plus"),
            style = "color: white"
          )
        ),
        size = "s",

        # modal content
        htmltools::br(),
        email_input,
        htmltools::br(),
        htmltools::div(
          class = "text-center",
          shiny::radioButtons(
            ns("user_is_admin"),
            "Is Admin?",
            choices = c(
              "Yes",
              "No"
            ),
            selected = is_admin_value,
            inline = TRUE
          )
        )
      )
    )
  })


  # TODO: validate inputs

  users_trigger <- reactiveVal(0)

  # the firebase function to add the user is triggered in the client side js, not in Shiny
  shiny::observeEvent(input$submit, {
    session_user <- session$userData$user()$user_uid
    input_email <- input$user_email
    input_is_admin <- input$user_is_admin

    is_admin_out <- if (input_is_admin == "Yes") TRUE else FALSE


    hold_user <- user_to_edit()

    users_params <- list(
      input_email
    )

    if (is.null(hold_user)) {
      # adding a new user
      tryCatch({

        if (is.null(.global_sessions$api_key)) {
          create_app_user(
            conn = .global_sessions$conn,
            app_uid = .global_sessions$app_name,
            email = input_email,
            is_admin = is_admin_out,
            created_by = session_user
          )
        } else {
          res <- httr::POST(
            url = paste0(.global_sessions$hosted_url, "/app-users"),
            body = list(
              email = input_email,
              app_uid = .global_sessions$app_name,
              is_admin = is_admin_out
            ),
            httr::authenticate(
              user = .global_sessions$api_key,
              password = ""
            ),
            encode = "json"
          )
          browser()
          httr::stop_for_status(res)

        }


        shiny::removeModal()


        users_trigger(users_trigger() + 1)
        tychobratools::show_toast("success", "User successfully added!")
      }, error = function(e) {
        tychobratools::show_toast("error", "Error adding user")
        print(e)
      })

    } else {
      # editing an existing user

      shiny::removeModal()

      tryCatch({
        DBI::dbWithTransaction(.global_sessions$conn, {

          # update the app user
          DBI::dbExecute(
            .global_sessions$conn,
            "UPDATE polished.app_users SET is_admin=$1, modified_by=$2, modified_at=$3 WHERE user_uid=$4 AND app_uid=$5",
            params = list(
              is_admin_out,                   # is_admin
              session_user,                   # modified_by
              tychobratools::time_now_utc(),  # modified_at
              hold_user$user_uid,             # user_uid
              .global_sessions$app_name       # app_name
            )
          )

        })

        users_trigger(users_trigger() + 1)
        tychobratools::show_toast("success", "User successfully edited!")
      }, error = function(e) {

        tychobratools::show_toast("error", "Error editing user")
        print(e)

      })

    }





  }, ignoreInit = TRUE)


  return(list(
    users_trigger = users_trigger
  ))
}
