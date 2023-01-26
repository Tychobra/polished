#' admin user access_ui
#'
#' Shiny module UI for the default user access tab in the \code{polished} Admin Panel.
#'
#' @param id the module id
#'
#' @importFrom shiny NS fluidRow column actionButton icon
#' @importFrom shinydashboard tabItem box
#' @importFrom shinycssloaders withSpinner
#' @importFrom htmltools br tags
#' @importFrom DT DTOutput
#'
#' @return the UI to create the user access module.
#'
#' @export
#'
user_access_module_ui <- function(id) {
  ns <- shiny::NS(id)

  shinydashboard::tabItem(
    tabName = "user_access",
    shiny::fluidRow(
      tags$style(
        paste0(
          "#", ns('users_table'), " .dataTables_length {
            padding-top: 10px;
          }"
        )
      ),
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
              icon = shiny::icon("user-plus")
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
      ),
      shiny::column(
        12,
        br(),
        br()
      )
    ),
    # users table
    tags$script(src = "polish/js/user_access_module.js?version=2"),
    tags$script(paste0("user_access_module('", ns(''), "')"))
  )
}

#' admin user access module
#'
#' Server function for the default Shiny module to control user access in the \code{polished}
#' Admin Panel.
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny showModal modalDialog removeModal reactiveVal reactive observeEvent callModule req eventReactive
#' @importFrom htmltools tags
#' @importFrom DT renderDT datatable dataTableProxy formatDate replaceData JS
#' @importFrom dplyr filter select %>% left_join mutate
#' @importFrom tibble tibble as_tibble
#' @importFrom shinyFeedback showToast
#' @importFrom purrr map_chr
#' @importFrom lubridate force_tz as_datetime
#' @importFrom rlang .data
#' @importFrom httr GET authenticate stop_for_status content
#' @importFrom jsonlite fromJSON
#'
#' @return \code{invisible(NULL)}
#'
#' @export
#'
user_access_module <- function(input, output, session) {
  ns <- session$ns

  # trigger to reload the `users` reactive from the database
  users_trigger <- reactiveVal(0)
  users <- reactive({
    users_trigger()


    out <- NULL
    tryCatch({

      app_users_res <- get_app_users(
        app_uid = .polished$app_uid
      )

      app_users <- app_users_res$content

      app_users <- app_users %>%
        mutate(created_at = as.POSIXct(.data$created_at))

      res <- httr::GET(
        url = paste0(.polished$api_url, "/last-active-session-time"),
        query = list(
          app_uid = .polished$app_uid
        ),
        httr::authenticate(
          user = get_api_key(),
          password = ""
        )
      )

      httr::stop_for_status(res)

      last_active_times <- jsonlite::fromJSON(
        httr::content(res, "text", encoding = "UTF-8")
      )

      last_active_times <- tibble::as_tibble(last_active_times)

      last_active_times <- last_active_times %>%
        mutate(last_sign_in_at = lubridate::force_tz(lubridate::as_datetime((.data$last_sign_in_at)), tzone = "UTC"))

      out <- app_users %>%
        left_join(last_active_times, by = 'user_uid')

    }, error = function(err) {

      msg <- "unable to get users"
      warning(msg)
      warning(conditionMessage(err))

      showToast(
        "error",
        msg,
        .options = polished_toast_options
      )
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

        if (isTRUE(the_row$is_admin)) {
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
      callback = DT::JS("$( table.table().container() ).addClass( 'table-responsive' ); return table;"),
      options = list(
        dom = 'ftlp',
        columnDefs = list(
          list(targets = 0, orderable = FALSE),
          list(targets = 0, class = "dt-center"),
          list(targets = 0, width = "105px")
        ),
        order = list(
          list(4, 'desc')
        ),
        # removes any lingering tooltips
        drawCallback = JS("function(settings) {
          $('.tooltip').remove();
        }")
      )
    ) %>%
      DT::formatDate(5, method = "toLocaleString")
  })

  users_proxy <- DT::dataTableProxy("users_table")

  add_user_return <- shiny::callModule(
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

  edit_user_return <- shiny::callModule(
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
    app_uid <- .polished$app_uid

    tryCatch({

      res <- httr::DELETE(
        url = paste0(.polished$api_url, "/app-users"),
        body = list(
          user_uid = user_uid,
          app_uid = app_uid,
          req_user_uid = session$userData$user()$user_uid
        ),
        httr::authenticate(
          user = get_api_key(),
          password = ""
        ),
        encode = "json"
      )

      httr::stop_for_status(res)

      shinyFeedback::showToast(
        "success",
        "User successfully deleted",
        .options = polished_toast_options
      )
      users_trigger(users_trigger() + 1)
    }, error = function(err) {

      msg <- "unable to delete delete user"
      warning(msg)
      shinyFeedback::showToast(
        "error",
        msg,
        .options = polished_toast_options
      )
      warning(conditionMessage(err))

      invisible(NULL)
    })

  })


  shiny::observeEvent(input$sign_in_as_btn_user_uid, {
    hold_user <- session$userData$user()

    user_to_sign_in_as <- users() %>%
      filter(.data$user_uid == input$sign_in_as_btn_user_uid) %>%
      dplyr::pull("user_uid")

    # sign in as another user
    update_session(
      session_uid = hold_user$session_uid,
      session_data = list(
        signed_in_as = user_to_sign_in_as
      )
    )

    # to to the Shiny app
    remove_query_string(mode = "push")

    session$reload()
  }, ignoreInit = TRUE)

  invisible(NULL)
}
