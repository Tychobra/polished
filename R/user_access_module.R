#' admin_user_access_ui
#'
#' @param id the module id
#'
#' @importFrom shiny fluidRow column actionButton
#' @importFrom shinydashboard tabItem box
#' @importFrom shinycssloaders withSpinner
#' @importFrom htmltools br tags
#' @importFrom DT DTOutput replaceData
#'
#'
#' @export
user_access_module_ui <- function(id) {
  ns <- shiny::NS(id)

  shinydashboard::tabItem(
    tabName = "user_access",
    shiny::fluidRow(
      shinydashboard::box(
        width = 12,
        title = "Users",
        #style = "min-height: 500px;",
        collapsible = TRUE,
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

    # roles_table_ui
    shiny::fluidRow(
      shinydashboard::box(
        title = "User Roles",
        width = 6,
        shiny::actionButton(
          ns("add_role"),
          "Add Role",
          class = "btn-success",
          style = "color: #fff;",
          icon = icon("plus")
        ),
        DT::DTOutput(ns("roles_table")) %>%
          shinycssloaders::withSpinner(
            type = 8,
            proxy.height = "500px"
          )
      )
    ),

    # users table
    tags$script(paste0("
      $(document).on('click', '#", ns('users_table'), " .sign_in_as_btn', function() {
        $(this).tooltip('hide');
        Shiny.setInputValue('", ns('sign_in_as_btn_user_uid'), "', this.id, { priority: 'event'});
      });
      $(document).on('click', '#", ns('users_table'), " .delete_btn', function() {
        $(this).tooltip('hide');
        Shiny.setInputValue('", ns('user_uid_to_delete'), "', this.id, { priority: 'event'});
      });
      $(document).on('click', '#", ns('users_table'), " .edit_btn', function() {
        $(this).tooltip('hide');
        Shiny.setInputValue('", ns('user_uid_to_edit'), "', this.id, { priority: 'event'});
      });
    ")),
    # roles table
    tags$script(paste0("
      $(document).on('click', '#", ns('roles_table'), " .delete_btn', function() {
        $(this).tooltip('hide');
        Shiny.setInputValue('", ns('role_uid_to_delete'), "', this.id, { priority: 'event'});
      });
    "))
  )
}

#' admin_user_access
#'
#' @param input the Shiny server input
#' @param output the Shiny server output
#' @param session the Shiny server session
#'
#' @importFrom shiny showModal modalDialog removeModal reactiveVal reactive observeEvent callModule
#' @importFrom htmltools br div
#' @importFrom DT renderDT datatable dataTableProxy formatDate
#' @importFrom dbplyr in_schema
#' @importFrom tidyr nest
#' @importFrom DBI dbExecute dbWithTransaction
#' @importFrom dplyr tbl filter select %>% left_join arrange collect mutate
#' @importFrom tibble tibble
#' @importFrom tychobratools show_toast format_dt_time
#' @importFrom purrr map_chr
#'
#' @export
#'
user_access_module <- function(input, output, session) {
  ns <- session$ns

  # trigger to reload the `users` reactive from the database
  users_trigger <- reactiveVal(0)
  users <- reactive({
    users_trigger()

    hold_app_name <- .global_sessions$app_name

    get_app_users(
      .global_sessions$conn,
      hold_app_name
    )
  })

  user_roles <- reactive({
    users_trigger()
    roles_trigger()

    hold_app_name <- .global_sessions$app_name

    .global_sessions$conn %>%
      dplyr::tbl(dbplyr::in_schema("polished", "user_roles")) %>%
      dplyr::filter(.data$app_name == hold_app_name) %>%
      dplyr::select(.data$user_uid, .data$role_uid) %>%
      dplyr::collect()
  })

  user_role_names <- reactive({
    user_roles() %>%
      dplyr::left_join(roles(), by = c("role_uid" = "uid")) %>%
      dplyr::select(.data$user_uid, .data$role_uid, role_name = .data$name) %>%
      tidyr::nest(roles = c(.data$role_uid, .data$role_name))
  })


  users_w_roles <- reactive({
    users() %>%
      left_join(user_role_names(), by = "user_uid")
  })

  users_table_prep <- reactiveVal(NULL)
  observeEvent(users_w_roles(), {

    out <- users_w_roles()
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


      roles_out <- lapply(out$roles, function(user_roles) {
        paste(user_roles$role_name, collapse = ", ")
      })

      out <- cbind(
        tibble::tibble(actions = unlist(actions)),
        out
      ) %>%
        dplyr::mutate(
          invite_status = ifelse(is.na(.data$last_sign_in_at), "Pending", "Accepted"),
          role = roles_out
        ) %>%
        dplyr::select(.data$actions, .data$email, .data$invite_status, .data$is_admin, .data$role, .data$last_sign_in_at)
    }

    if (is.null(users_table_prep())) {
      users_table_prep(out)
    } else {
      DT::replaceData(users_proxy, out, resetPaging = FALSE, rownames = FALSE)
    }

  })

  output$users_table <- DT::renderDT({
    req(users_table_prep())
    out <- users_table_prep()

    if (nrow(out) > 10) {
      dom_out <-  "ftp"
    } else {
      dom_out <- "ft"
    }

    DT::datatable(
      out,
      rownames = FALSE,
      colnames = c(
        "",
        "Email",
        "Invite Status",
        "Is Admin?",
        "Role",
        "Last Sign In"
      ),
      escape = -1,
      selection = "none",
      options = list(
        dom = dom_out,
        scrollX = TRUE,
        columnDefs = list(
          list(targets = 0, orderable = FALSE),
          list(targets = 0, class = "dt-center"),
          list(targets = 0, width = "105px")
        ),
        rowCallback = tychobratools::format_dt_time(6)
      )
    )

  })

  users_proxy <- DT::dataTableProxy("users_table")

  add_user_return <- callModule(
    user_edit_module,
    "add_user",
    modal_title = "Add User",
    user_to_edit = function() NULL,
    open_modal_trigger = reactive({input$add_user}),
    existing_roles = roles,
    existing_users = users
  )

  observeEvent(add_user_return$users_trigger(), {
    users_trigger(users_trigger() + 1)
  }, ignoreInit = TRUE)



  user_to_edit <- reactiveVal(NULL)
  observeEvent(input$user_uid_to_edit, {

    out <- users_w_roles() %>%
      dplyr::filter(.data$user_uid == input$user_uid_to_edit)

    user_to_edit(out)
  }, priority = 1)

  edit_user_return <- callModule(
    user_edit_module,
    "edit_user",
    modal_title = "Edit User",
    user_to_edit = user_to_edit,
    open_modal_trigger = reactive({input$user_uid_to_edit}),
    existing_roles = roles,
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
    req(nrow(hold_user) == 1)

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
        htmltools::br(),
        h3(paste0("Are you sure you want to delete ", hold_user$email, "?"))
      )
    )

  })


  shiny::observeEvent(input$submit_user_delete, {
    shiny::removeModal()

    user_uid <- user_to_delete()$user_uid

    tryCatch({
      DBI::dbExecute(
        .global_sessions$conn,
        "DELETE FROM polished.app_users WHERE user_uid=$1",
        params = list(user_uid)
      )

      show_toast("success", "User successfully deleted")
      users_trigger(users_trigger() + 1)
    }, error = function(e) {
      show_toast("error", "Error deleting user")
      print(e)
    })

  })






  shiny::observeEvent(input$add_role, {

    shiny::showModal(
      shiny::modalDialog(
        title = "Add Role",
        footer = list(
          modalButton("Cancel"),
          actionButton(
            ns("submit_role_add"),
            "Add Role",
            class = "btn-success",
            style = "color: white",
            icon = icon("plus")
          )
        ),
        size = "s",
        shiny::textInput(
          inputId = ns("new_user_role"),
          label = "New Role"
        )
      )
    )
  })






  valid_new_role <- eventReactive(input$submit_role_add, {
    role_input <- input$new_user_role

    if (role_input %in% roles()$name) {

      tychobratools::show_toast("error", "Role already exists")
      return(NULL)

    } else if (role_input == "") {

      tychobratools::show_toast("error", "Invalid role name")
      return(NULL)

    } else {
      removeModal()

      return(role_input)
    }
  })



  observeEvent(valid_new_role(), {
    new_role <- valid_new_role()
    user_uid <- session$userData$user()$uid

    tryCatch({

      dbExecute(
        .global_sessions$conn,
        "INSERT INTO polished.roles ( uid, name, app_name, created_by, modified_by ) VALUES ( $1, $2, $3, $4, $5 )",
        params = list(
          create_uid(),
          new_role,
          .global_sessions$app_name,
          user_uid,
          user_uid
        )
      )

      roles_trigger(roles_trigger() + 1)
      show_toast("success", "Role successfully Added")
    }, error = function(e) {

      print(e)
      show_toast("error", "Error adding role")
    })


  })

  roles_trigger <- reactiveVal(0)
  roles <- reactive({
    roles_trigger()

    hold_app_name <- .global_sessions$app_name

    .global_sessions$conn %>%
      dplyr::tbl(dbplyr::in_schema("polished", "roles")) %>%
      dplyr::filter(.data$app_name == hold_app_name) %>%
      dplyr::select(.data$uid, .data$name) %>%
      dplyr::collect()
  })



  roles_table_prep <- reactive({
    req(roles())

    out <- roles()

    n_rows <- nrow(out)

    if (n_rows == 0) {
      actions <- character(0)
    } else {
      rows <- seq_len(n_rows)

      actions <- purrr::map_chr(rows, function(i) {

        paste0(
          '<button class="btn btn-danger btn-sm delete_btn" data-toggle="tooltip" data-placement="top" title="Delete Role" id = ',
          out[i, ]$uid,
          ' style="margin: 0"><i class="fa fa-trash-o"></i></button></div>'
        )
      })

    }

    out <- out %>%
      select(-.data$uid)

    cbind(
      tibble::tibble(actions = actions),
      out
    )
  })


  output$roles_table <- DT::renderDT({
    req(roles_table_prep())

    out <- roles_table_prep()

    if (nrow(out) > 10) {
      dom_out <- "tp"
    } else {
      dom_out <- "t"
    }

    DT::datatable(
      roles_table_prep(),
      rownames = FALSE,
      colnames = c(" ", "Role"),
      escape = -1,
      selection = "none",
      options = list(
        dom = dom_out,
        columnDefs = list(
          list(targets = 0:1, class = "dt-center"),
          list(targets = 0, width = "35px")
        )
      )
    )
  })




  role_to_delete <- reactiveVal(NULL)

  observeEvent(input$role_uid_to_delete, {

    out <- roles() %>%
      dplyr::filter(.data$uid == input$role_uid_to_delete)

    role_to_delete(out)
  }, priority = 1)

  observeEvent(input$role_uid_to_delete, {
    hold_role <- role_to_delete()
    req(nrow(hold_role) == 1)

    shiny::showModal(
      shiny::modalDialog(
        title = "Delete User",
        footer = list(
          modalButton("Cancel"),
          actionButton(
            ns("submit_role_delete"),
            "Delete Role",
            class = "btn-danger",
            style = "color: white",
            icon = icon("times")
          )
        ),
        size = "m",
        htmltools::br(),
        h3(
          style = "line-height: 1.3;",
          paste0(
            'Are you sure you want to delete role: "', hold_role$name, '"?  Any ',
            'users with this role will lose it.'
          )
        )
      )
    )

  })


  shiny::observeEvent(input$submit_role_delete, {
    shiny::removeModal()

    role_uid <- role_to_delete()$uid

    tryCatch({

      dbWithTransaction(.global_sessions$conn, {
        DBI::dbExecute(
          .global_sessions$conn,
          "DELETE FROM polished.user_roles WHERE role_uid=$1",
          params = list(role_uid)
        )

        DBI::dbExecute(
          .global_sessions$conn,
          "DELETE FROM polished.roles WHERE uid=$1",
          params = list(role_uid)
        )
      })

      tychobratools::show_toast("success", "Role successfully deleted")
      roles_trigger(roles_trigger() + 1)
    }, error = function(e) {
      tychobratools::show_toast("error", "Error deleting role")
      print(e)
    })




  })



  shiny::observeEvent(input$sign_in_as_btn_user_uid, {
    user_to_sign_in_as <- users_w_roles() %>%
      filter(.data$user_uid == input$sign_in_as_btn_user_uid) %>%
      dplyr::select(.data$email, .data$is_admin, uid = .data$user_uid, .data$roles) %>%
      as.list()

    roles_out <- user_to_sign_in_as$roles[[1]]$role_name
    if (is.null(roles_out)) {
      user_to_sign_in_as$roles <- character(0)
    } else {
      user_to_sign_in_as$roles <- roles_out
    }

    user_to_sign_in_as$token <- session$userData$user()$token

    session$sendCustomMessage(
      "polish__show_loading",
      message = list(
        text = "Loading..."
      )
    )

    # sign in as another user
    .global_sessions$set_signed_in_as(
      session$userData$user()$token,
      user_to_sign_in_as
    )

    # to to the Shiny app
    remove_query_string(session)

    session$reload()
  }, ignoreInit = TRUE)

}
