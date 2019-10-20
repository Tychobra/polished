#' user_edit_module
#'
#' @param input Shiny server function input
#' @param output Shiny sever function output
#' @param session Shiny server function session
#' @param modal_title the title for the modal
#' @param user_to_edit reactive - a one row data frame of the user to edit from the "app_users" table.
#' @param open_modal_trigger reactive - a trigger to open the modal
#' @param existing_roles reactive data frame of all roles for this app
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
  existing_roles,
  existing_users
) {

  ns <- session$ns



  role_choices <- reactive({
    hold_roles <- existing_roles()
    hold_user <- user_to_edit()

    choices <- hold_roles$uid
    names(choices) <- hold_roles$name

    if (is.null(hold_user)) {
      out <- list(
        choices = choices,
        selected = NULL
      )
    } else {
      out <- list(
        choices = choices,
        selected = hold_user$roles[[1]]$role_uid
      )
    }

    out
  })

  shiny::observeEvent(open_modal_trigger(), {
    hold_user <- user_to_edit()
    hold_role_choices <- role_choices()

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
        ),
        shinyWidgets::pickerInput(
          ns("user_custom_role"),
          "Role",
          choices = hold_role_choices$choices,
          multiple = TRUE,
          selected = hold_role_choices$selected,
          options = list(
            `none-selected-text` = "No Roles"
          )
        )
      )
    )
  })


  # TODO: validate inputs

  users_trigger <- reactiveVal(0)

  # the firebase function to add the user is triggered in the client side js, not in Shiny
  shiny::observeEvent(input$submit, {
    session_user <- session$userData$user()$uid
    input_email <- input$user_email
    input_is_admin <- input$user_is_admin
    input_roles <- input$user_custom_role

    is_admin_out <- if (input_is_admin == "Yes") TRUE else FALSE


    hold_user <- user_to_edit()

    users_params <- list(
      input_email
    )

    if (is.null(hold_user)) {
      # adding a new user
      tryCatch({
        create_app_user(
          conn = .global_sessions$conn,
          app_name = .global_sessions$app_name,
          email = input_email,
          is_admin = is_admin_out,
          roles = input_roles,
          created_by = session_user
        )

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

          # add user to app_users
          DBI::dbExecute(
            .global_sessions$conn,
            "UPDATE polished.app_users SET is_admin=$1, modified_by=$2, modified_at=$3 WHERE user_uid=$4 AND app_name=$5",
            params = list(
              is_admin_out,                   # is_admin
              session_user,                   # modified_by
              tychobratools::time_now_utc(),  # modified_at
              hold_user$user_uid,             # user_uid
              .global_sessions$app_name       # app_name
            )
          )

          # edit user roles
          # delete any existing roles for this user
          DBI::dbExecute(
            .global_sessions$conn,
            "DELETE FROM polished.user_roles WHERE user_uid=$1 AND app_name=$2",
            params = list(
              hold_user$user_uid, # user_uid
              .global_sessions$app_name
            )
          )

          if (length(input_roles) > 0) {

            # create table of new roles to insert into "user_roles"
            new_roles <- data.frame(
              user_uid = hold_user$user_uid,
              role_uid = input_roles,
              app_name = .global_sessions$app_name,
              created_by = session_user,
              stringsAsFactors = FALSE
            )

            # append new roles to "user_roles" table
            DBI::dbWriteTable(
              .global_sessions$conn,
              name = DBI::Id(schema = "polished", table = "user_roles"),
              value = new_roles,
              append = TRUE,
              overwrite = FALSE
            )
          }


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
