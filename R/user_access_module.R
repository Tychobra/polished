#' admin_user_access_ui
#'
#' @param id the module id
#'
#' @importFrom shiny fluidRow column actionButton
#' @importFrom shinydashboard tabItem box
#' @importFrom shinycssloaders withSpinner
#' @importFrom htmltools br tags
#' @importFrom DT DTOutput
#'
#'
user_access_module_ui <- function(id) {
  ns <- shiny::NS(id)

  shinydashboard::tabItem(
    tabName = "user_access",
    shiny::fluidRow(
      shinydashboard::box(
        width = 12,
        title = "Users",
        #style = "min-height: 500px;",
        # collapsible = TRUE,
        shiny::fluidRow(
          shiny::column(
            12,
            shiny::actionButton(
              ns("add_user"),
              "Add User",
              class = "btn-success",
              #style = "color: #fff; position: absolute: top: 20, left: 15; margin-bottom: 0;",
              style = "color: #fff;",
              icon = icon("user-plus")
            )
          )
        ),
        shiny::fluidRow(
          shiny::column(
            12,
            style = "z-index: 10",
            DT::DTOutput(ns("users_table")) %>%
              shinycssloaders::withSpinner(
                type = 8,
                proxy.height = "300px"
              )
          )
        )
      )
    ),
    # users table
    tags$script(src = "polish/js/user_access_module.js?version=2"),
    tags$script(paste0("user_access_module('", ns(''), "')"))
  )
}

#' admin_user_access
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny showModal modalDialog removeModal reactiveVal reactive observeEvent callModule req eventReactive
#' @importFrom htmltools tags
#' @importFrom DT renderDT datatable dataTableProxy formatDate replaceData
#' @importFrom dplyr filter select %>% left_join mutate
#' @importFrom tibble tibble
#' @importFrom shinyFeedback showToast
#' @importFrom purrr map_chr
#' @importFrom lubridate force_tz
#'
#'
user_access_module <- function(input, output, session) {
  ns <- session$ns

  # trigger to reload the `users` reactive from the database
  users_trigger <- reactiveVal(0)
  users <- reactive({
    users_trigger()

    hold_app_name <- .global_sessions$app_name

    out <- NULL
    tryCatch({

      res <- httr::GET(
        url = paste0(.global_sessions$hosted_url, "/app-users"),
        query = list(
          app_uid = hold_app_name
        ),
        httr::authenticate(
          user = .global_sessions$api_key,
          password = ""
        )
      )

      httr::stop_for_status(res)

      app_users <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )


      if (length(app_users) == 0) {
        app_users <- tibble::tibble(
          "uid" = character(0),
          "app_uid" = character(0),
          "user_uid" = character(0),
          "is_admin" = logical(0),
          "created_at" = as.POSIXct(character(0)),
          "email" = character(0)
        )
      } else {
        app_users <- app_users %>%
          mutate(created_at = as.POSIXct(.data$created_at))
      }


      res <- httr::GET(
        url = paste0(.global_sessions$hosted_url, "/last-active-session-time"),
        query = list(
          app_uid = hold_app_name
        ),
        httr::authenticate(
          user = .global_sessions$api_key,
          password = ""
        )
      )

      httr::stop_for_status(res)

      last_active_times <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )


      if (length(last_active_times) == 0) {
        last_active_times <- tibble::tibble(
          user_uid = character(0),
          last_sign_in_at = character(0)
        )
      }

      last_active_times <- last_active_times %>%
        mutate(last_sign_in_at = lubridate::force_tz(as.POSIXct(.data$last_sign_in_at), tzone = "UTC"))

      out <- app_users %>%
        left_join(last_active_times, by = 'user_uid')

    }, error = function(err) {

      print("[polished] error")
      print(err)

      showToast("error", "Error retrieving app users from API")
    })

    out
  })

  users_table_prep <- reactiveVal(NULL)
  observeEvent(users(), {

    out <- users()
    n_rows <- nrow(out)

    if (n_rows == 0) {
      actions <- character(0)
    } else {

      actions <- purrr::map_chr(seq_len(n_rows), function(row_num) {

        the_row <- out[row_num, ]

        if (.global_sessions$get_admin_mode()) {
          buttons_out <- paste0('<div class="btn-group" style="width: 105px" role="group" aria-label="User Action Buttons">
            <button class="btn btn-default btn-sm sign_in_as_btn" data-toggle="tooltip" data-placement="top" title="Sign In As" id = ', the_row$user_uid, ' style="margin: 0" disabled><i class="fas fa-user-astronaut"></i></button>
            <button class="btn btn-primary btn-sm edit_btn" data-toggle="tooltip" data-placement="top" title="Edit User" id = ', the_row$user_uid, ' style="margin: 0"><i class="fa fa-pencil-square-o"></i></button>
            <button class="btn btn-danger btn-sm delete_btn" id = ', the_row$user_uid, ' style="margin: 0" disabled><i class="fa fa-trash-o"></i></button>
          </div>')
        } else if (isTRUE(the_row$is_admin)) {
          buttons_out <- paste0('<div class="btn-group" style="width: 105px" role="group" aria-label="User Action Buttons">
            <button class="btn btn-default btn-sm sign_in_as_btn" data-toggle="tooltip" data-placement="top" title="Sign In As" id = ', the_row$user_uid, ' style="margin: 0"><i class="fas fa-user-astronaut"></i></button>
            <button class="btn btn-primary btn-sm edit_btn" data-toggle="tooltip" data-placement="top" title="Edit User" id = ', the_row$user_uid, ' style="margin: 0"><i class="fa fa-pencil-square-o"></i></button>
            <button class="btn btn-danger btn-sm delete_btn" id = ', the_row$user_uid, ' style="margin: 0" disabled><i class="fa fa-trash-o"></i></button>
          </div>')
        } else {
          buttons_out <- paste0('<div class="btn-group" style="width: 105px" role="group" aria-label="User Action Buttons">
            <button class="btn btn-default btn-sm sign_in_as_btn" data-toggle="tooltip" data-placement="top" title="Sign In As" id = ', the_row$user_uid, ' style="margin: 0"><i class="fas fa-user-astronaut"></i></button>
            <button class="btn btn-primary btn-sm edit_btn" data-toggle="tooltip" data-placement="top" title="Edit User" id = ', the_row$user_uid, ' style="margin: 0"><i class="fa fa-pencil-square-o"></i></button>
            <button class="btn btn-danger btn-sm delete_btn" data-toggle="tooltip" data-placement="top" title="Delete User" id = ', the_row$user_uid, ' style="margin: 0"><i class="fa fa-trash-o"></i></button>
          </div>')
        }

        buttons_out
      })


      out <- cbind(
        tibble::tibble(actions = actions),
        out
      ) %>%
        dplyr::mutate(
          invite_status = ifelse(is.na(.data$last_sign_in_at), "Pending", "Accepted")
        ) %>%
        dplyr::select(.data$actions, .data$email, .data$invite_status, .data$is_admin, .data$last_sign_in_at)
    }

    if (is.null(users_table_prep())) {
      users_table_prep(out)
    } else {
      shinyjs::runjs("$('.btn-sm').tooltip('hide')")
      DT::replaceData(users_proxy, out, resetPaging = FALSE, rownames = FALSE)
    }

  })

  output$users_table <- DT::renderDT({
    shiny::req(users_table_prep())
    out <- users_table_prep()

    DT::datatable(
      out,
      rownames = FALSE,
      colnames = c(
        "",
        "Email",
        "Invite Status",
        "Is Admin?",
        "Last Sign In"
      ),
      escape = -1,
      selection = "none",
      callback = JS("$( table.table().container() ).addClass( 'table-responsive' ); return table;"),
      options = list(
        dom = 'ftp',
        columnDefs = list(
          list(targets = 0, orderable = FALSE),
          list(targets = 0, class = "dt-center"),
          list(targets = 0, width = "105px")
        )
      )
    ) %>%
      DT::formatDate(5, method = "toLocaleString")
  })

  users_proxy <- DT::dataTableProxy("users_table")

  add_user_return <- callModule(
    user_edit_module,
    "add_user",
    modal_title = "Add User",
    user_to_edit = function() NULL,
    open_modal_trigger = reactive({input$add_user}),
    existing_users = users
  )

  observeEvent(add_user_return$users_trigger(), {
    users_trigger(users_trigger() + 1)
  }, ignoreInit = TRUE)



  user_to_edit <- reactiveVal(NULL)
  observeEvent(input$user_uid_to_edit, {

    out <- users() %>%
      dplyr::filter(.data$user_uid == input$user_uid_to_edit)

    user_to_edit(out)
  }, priority = 1)

  edit_user_return <- callModule(
    user_edit_module,
    "edit_user",
    modal_title = "Edit User",
    user_to_edit = user_to_edit,
    open_modal_trigger = reactive({input$user_uid_to_edit}),
    existing_users = users
  )

  observeEvent(edit_user_return$users_trigger(), {
    users_trigger(users_trigger() + 1)
  }, ignoreInit = TRUE)






  user_to_delete <- reactiveVal(NULL)
  observeEvent(input$user_uid_to_delete, {

    out <- users() %>%
      dplyr::filter(.data$user_uid == input$user_uid_to_delete)

    user_to_delete(out)
  }, priority = 1)



  observeEvent(input$user_uid_to_delete, {
    hold_user <- user_to_delete()
    shiny::req(nrow(hold_user) == 1)

    shiny::showModal(
      shiny::modalDialog(
        title = "Delete User",
        footer = list(
          modalButton("Cancel"),
          actionButton(
            ns("submit_user_delete"),
            "Delete User",
            class = "btn-danger",
            style = "color: white",
            icon = icon("times")
          )
        ),
        size = "m",

        # modal content
        tags$div(
          class = "text-center",
          style = "padding: 30px;",
          tags$h3(
            style = "line-height: 1.5;",
            HTML(paste0(
            "Are you sure you want to delete ", tags$b(hold_user$email), "?"
            ))
          ),
          tags$br()
        )
      )
    )

  })


  shiny::observeEvent(input$submit_user_delete, {
    shiny::removeModal()

    user_uid <- user_to_delete()$user_uid
    app_uid <- .global_sessions$app_name

    tryCatch({

      res <- httr::DELETE(
        url = paste0(.global_sessions$hosted_url, "/app-users"),
        body = list(
          user_uid = user_uid,
          app_uid = app_uid,
          req_user_uid = session$userData$user()$user_uid
        ),
        httr::authenticate(
          user = .global_sessions$api_key,
          password = ""
        ),
        encode = "json"
      )

      httr::stop_for_status(res)

      shinyFeedback::showToast("success", "User successfully deleted")
      users_trigger(users_trigger() + 1)
    }, error = function(e) {
      shinyFeedback::showToast("error", "Error deleting user")
      print(e)
    })

  })


  shiny::observeEvent(input$sign_in_as_btn_user_uid, {
    req(!.global_sessions$get_admin_mode())
    hold_user <- session$userData$user()

    user_to_sign_in_as <- users() %>%
      filter(.data$user_uid == input$sign_in_as_btn_user_uid) %>%
      dplyr::pull("user_uid")


    session$sendCustomMessage(
      "polish__show_loading",
      message = list(
        text = "Loading..."
      )
    )

    # sign in as another user
    .global_sessions$set_signed_in_as(
      hold_user$session_uid,
      user_to_sign_in_as,
      user_uid = hold_user$user_uid
    )

    # to to the Shiny app
    remove_query_string(session)

    session$reload()
  }, ignoreInit = TRUE)

}
