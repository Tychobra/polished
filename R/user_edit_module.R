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
#'
#' @importFrom shiny reactive observeEvent showModal modalDialog modalButton removeModal HTML
#' @importFrom shinyWidgets pickerInput
#' @importFrom shinyFeedback showToast
#' @importFrom httr GET authenticate content status_code
#' @importFrom jsonlite fromJSON
#'
#' @return a list with one element named "users_trigger".  The "users_trigger" is a reactive value that
#' increments by 1 after an edit is completed.
#'
#' @noRd
#'
user_edit_module <- function(input, output, session,
  modal_title,
  user_to_edit,
  open_modal_trigger,
  existing_users
) {

  ns <- session$ns

  app_url <- reactiveVal(NULL)

  # get the app_url
  observeEvent(open_modal_trigger(), {

    tryCatch({
      res <- httr::GET(
        url = paste0(.polished$api_url, "/apps"),
        query = list(
          app_uid = .polished$app_uid
        ),
        httr::authenticate(
          user = get_api_key(),
          password = ""
        )
      )

      res_content <- jsonlite::fromJSON(
        httr::content(res, type = "text", encoding = "UTF-8")
      )

      if (!identical(httr::status_code(res), 200L)) {
        app_url(NULL)
        stop(res_content, call. = FALSE)
      } else {
        app_url(res_content$app_url)
      }

    }, error = function(err) {
      warning(conditionMessage(err))
      invisible(NULL)
    })

  }, priority = 1)

  shiny::observeEvent(open_modal_trigger(), {
    hold_user <- user_to_edit()
    hold_app_url <- app_url()

    if (is.null(hold_user)) {
      # adding a new user
      is_admin_value  <- "No"

      email_input <- shiny::textInput(
        ns("user_email"),
        "Email",
        value = if (is.null(hold_user)) "" else hold_user$email
      )

      send_invite_ui <- tagList(
        br(),
        send_invite_checkbox(ns, hold_app_url)
      )


    } else {
      # editing and existing user

      if (isTRUE(hold_user$is_admin)) {
        is_admin_value <- "Yes"
      } else {
        is_admin_value <- "No"
      }

      email_input <- NULL

      send_invite_ui <- list()
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
          ),
          send_invite_ui
        ),
        tags$script(src = "polish/js/user_edit_module.js?version=2"),
        tags$script(paste0("user_edit_module('", ns(''), "')"))
      )
    )

    if (!is.null(email_input)) {

      observeEvent(input$user_email, {

        hold_email <- tolower(input$user_email)

        if (is_valid_email(hold_email)) {
          shinyFeedback::hideFeedback("user_email")
          shinyjs::enable("submit")
        } else {
          shinyjs::disable("submit")
          if (hold_email != "") {
            shinyFeedback::showFeedbackDanger(
              "user_email",
              text = "Invalid email"
            )
          } else {
            shinyFeedback::hideFeedback("user_email")
          }
        }
      })
    }
  })


  # TODO: validate inputs

  users_trigger <- reactiveVal(0)

  # the firebase function to add the user is triggered in the client side js, not in Shiny
  shiny::observeEvent(input$submit, {
    input_email <- tolower(input$user_email)
    input_is_admin <- input$user_is_admin

    is_admin_out <- if (input_is_admin == "Yes") TRUE else FALSE

    hold_user <- user_to_edit()

    if (is.null(hold_user)) {
      # adding a new user
      tryCatch({

        res <- httr::POST(
          url = paste0(.polished$api_url, "/app-users"),
          body = list(
            email = input_email,
            app_uid = .polished$app_uid,
            is_admin = is_admin_out,
            req_user_uid = session$userData$user()$user_uid,
            send_invite_email = input$send_invite_email
          ),
          httr::authenticate(
            user = get_api_key(),
            password = ""
          ),
          encode = "json"
        )

        if (!identical(httr::status_code(res), 200L)) {

          err <- jsonlite::fromJSON(
            httr::content(res, "text", encoding = "UTF-8")
          )

          stop(err$error, call. = FALSE)
        }



        shiny::removeModal()


        users_trigger(users_trigger() + 1)
        shinyFeedback::showToast(
          "success",
          "User successfully added!",
          .options = polished_toast_options
        )
      }, error = function(err) {

        err_msg <- conditionMessage(err)


        shinyFeedback::showToast(
          "error",
          err_msg,
          .options = polished_toast_options
        )

        warning(err_msg)

        invisible(NULL)
      })

    } else {
      # editing an existing user
      shiny::removeModal()

      tryCatch({
        # update the app user
        res <- httr::PUT(
          url = paste0(.polished$api_url, "/app-users"),
          body = list(
            user_uid = hold_user$user_uid,
            app_uid = .polished$app_uid,
            is_admin = is_admin_out,
            req_user_uid = session$userData$user()$user_uid
          ),
          httr::authenticate(
            user = get_api_key(),
            password = ""
          ),
          encode = "json"
        )

        if (!identical(httr::status_code(res), 200L)) {

          err <- jsonlite::fromJSON(
            httr::content(res, "text", encoding = "UTF-8")
          )

          stop(err, call. = FALSE)
        }

        users_trigger(users_trigger() + 1)
        shinyFeedback::showToast(
          "success",
          "User successfully edited!",
          .options = polished_toast_options
        )
      }, error = function(err) {

        msg <- "unable to edit user"

        warning(msg)

        shinyFeedback::showToast(
          "error",
          msg,
          .options = polished_toast_options
        )

        warning(conditionMessage(err))

        invisible(NULL)
      })
    }

  }, ignoreInit = TRUE)


  return(list(
    users_trigger = users_trigger
  ))
}
