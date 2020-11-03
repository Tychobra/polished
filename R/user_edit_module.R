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
        url = paste0(getOption("polished")$api_url, "/apps"),
        query = list(
          app_uid = getOption("polished")$app_uid
        ),
        httr::authenticate(
          user = getOption("polished")$api_key,
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
      print(err)
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
  })


  # TODO: validate inputs

  users_trigger <- reactiveVal(0)

  # the firebase function to add the user is triggered in the client side js, not in Shiny
  shiny::observeEvent(input$submit, {
    session_user <- session$userData$user()$user_uid
    input_email <- tolower(input$user_email)
    input_is_admin <- input$user_is_admin

    is_admin_out <- if (input_is_admin == "Yes") TRUE else FALSE


    hold_user <- user_to_edit()

    users_params <- list(
      input_email
    )

    if (is.null(hold_user)) {
      # adding a new user
      tryCatch({

        res <- httr::POST(
          url = paste0(getOption("polished")$api_url, "/app-users"),
          body = list(
            email = input_email,
            app_uid = getOption("polished")$app_uid,
            is_admin = is_admin_out,
            req_user_uid = session$userData$user()$user_uid,
            send_invite_email = input$send_invite_email
          ),
          httr::authenticate(
            user = getOption("polished")$api_key,
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



        shiny::removeModal()


        users_trigger(users_trigger() + 1)
        shinyFeedback::showToast(
          "success",
          "User successfully added!",
          .options = polished_toast_options
        )
      }, error = function(err) {

        if (err$message == "unique user limit exceeded") {
          shinyFeedback::showToast(
            "error",
            shiny::HTML(
              paste0(
                tags$div(
                  class = "text-center",
                  "Unique User Limit Exceeded!",
                  tags$br(),
                  "For unlimited users, enable billing in the ",
                  tags$a(
                    href = "https://dashboard.polished.tech",
                    target = "_blank",
                    tags$b("Polished Dashboard"),
                    shiny::icon("external-link-alt")
                  )
                )
              )
            ),
            .options = list(
              positionClass = "toast-top-center",
              newestOnTop = TRUE,
              timeOut = 0,
              extendedTimeOut = 0
            )
          )
        } else {
          shinyFeedback::showToast(
            "error",
            err$message,
            .options = polished_toast_options
          )
        }

        print(err)
      })

    } else {
      # editing an existing user

      shiny::removeModal()

      tryCatch({


        # update the app user
        res <- httr::PUT(
          url = paste0(getOption("polished")$api_url, "/app-users"),
          body = list(
            user_uid = hold_user$user_uid,
            app_uid = getOption("polished")$app_uid,
            is_admin = is_admin_out,
            req_user_uid = session$userData$user()$user_uid
          ),
          httr::authenticate(
            user = getOption("polished")$api_key,
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
      }, error = function(e) {

        shinyFeedback::showToast(
          "error",
          "Error editing user",
          .options = polished_toast_options
        )
        print(e)

      })

    }


  }, ignoreInit = TRUE)


  return(list(
    users_trigger = users_trigger
  ))
}
