library(shinycssloaders)
#' admin_user_access_ui
#'
#' @param id the module id
#'
#' @import shiny shinydashboard shinycssloaders
#' @importFrom htmltools br
#' @importFrom DT DTOutput
#'
#' @export
user_access_module_ui <- function(id) {
  ns <- shiny::NS(id)

  shinydashboard::tabItem(
    tabName = "user_access",
    shiny::fluidRow(
      shiny::column(
        12,
        # shiny::actionButton(
        #   ns("add_user"),
        #   "Add User",
        #   class = "btn-success",
        #   style = "color: #fff;",
        #   icon = icon("user-plus")
        # ),
        shiny::actionButton(
          ns("manage_roles"),
          "Manage User Roles",
          class = "btn-primary",
          style = "color: #fff;",
          icon = icon("cogs")
        ),
        htmltools::br(),
        htmltools::br()
      )
    ),
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
            DT::DTOutput(ns("users_table")) #%>%
            #shinycssloaders::withSpinner(
            #  type = 8,
            #  proxy.height = "500px"
            #)
          )
        )
      )
    ),
    # users table
    tags$script(paste0("
      $(document).on('click', '#", ns('users_table'), " .delete_btn', function() {
        //$(this).tooltip('hide');
        Shiny.setInputValue('", ns('user_row_to_delete'), "', this.id, { priority: 'event'});
      });
      $(document).on('click', '#", ns('users_table'), " .edit_btn', function() {
        //$(this).tooltip('hide');
        Shiny.setInputValue('", ns('user_row_to_edit'), "', this.id, { priority: 'event'});
      });
    ")),
    # roles table
    tags$script(paste0("
      $(document).on('click', '#", ns('roles_table'), " .delete_btn', function() {
        //$(this).tooltip('hide');
        Shiny.setInputValue('", ns('role_row_to_delete'), "', this.id, { priority: 'event'});
      });
      $(document).on('click', '#", ns('roles_table'), " .edit_btn', function() {
        //$(this).tooltip('hide');
        Shiny.setInputValue('", ns('role_row_to_edit'), "', this.id, { priority: 'event'});
      });
    "))
  )
}

#' admin_user_access
#'
#' @import shiny shinyjs dplyr
#' @importFrom htmltools br div
#' @importFrom DT renderDT datatable
#'
#' @export
#'
user_access_module <- function(input, output, session) {
  ns <- session$ns


  users <- shiny::reactiveVal(NULL)

  shiny::observe({
    users_trigger()

    session$sendCustomMessage(
      "polish__get_users",
      message = list(
        app_name = "auth_basic"
      )
    )
  })

  observeEvent(input$polish__users, {
    out <- input$polish__users %>%
      dplyr::mutate(
        time_created = as.POSIXct(time_created, format="%Y-%m-%dT%H:%M:%S", tz = "America/New_York"),
        time_last_signed_in = as.POSIXct(time_last_signed_in, format="%Y-%m-%dT%H:%M:%S", tz = "America/New_York"),
        is_admin = as.logical(is_admin)
      ) %>%
      dplyr::arrange(desc(time_created))

    users(out)
  })


  users_table_prep <- reactiveVal(NULL)
  observeEvent(users(), {

    out <- users() %>%
      dplyr::mutate(
        time_created = ifelse(
          as.Date(time_created, tz = "America/New_York") == Sys.Date(),
          strftime(time_created, format="%H:%M"),
          as.character(as.Date(time_created, tz = "America/New_York"))
        ),
        time_last_signed_in = ifelse(
          as.Date(time_last_signed_in, tz = "America/New_York") == Sys.Date(),
          strftime(time_last_signed_in, format="%H:%M"),
          as.character(as.Date(time_last_signed_in, tz = "America/New_York"))
        )
      )

    if (nrow(out) == 0) {
      actions <- character(0)
    } else {
      rows <- 1:nrow(out)

      actions <- paste0(
        '<div class="btn-group" style="width: 75px" role="group" aria-label="Basic example">
          <button class="btn btn-primary btn-sm edit_btn" data-toggle="tooltip" data-placement="top" title="Edit User" id = ', rows, ' style="margin: 0"><i class="fa fa-pencil-square-o"></i></button>
          <button class="btn btn-danger btn-sm delete_btn" data-toggle="tooltip" data-placement="top" title="Delete User" id = ', rows, ' style="margin: 0"><i class="fa fa-trash-o"></i></button></div>'
      )

      out <- cbind(
        tibble::tibble(actions = actions),
        out
      )
    }

    if (is.null(users_table_prep())) {
      users_table_prep(out)
    } else {
      replaceData(users_proxy, out, resetPaging = FALSE, rownames = FALSE)
    }

  })

  output$users_table <- DT::renderDT({
    req(users_table_prep())

    DT::datatable(
      users_table_prep(),
      rownames = FALSE,
      colnames = c(
        "Email",
        "Invite Status",
        "Is Admin?",
        "Role",
        "Time Invited",
        "Time Last Sign In"
      ),
      escape = -1,
      selection = "none",
      options = list(
        dom = "ftp",
        scrollX = TRUE
      )
    )
  })

  users_proxy <- DT::dataTableProxy("users_table")

  shiny::observeEvent(input$add_user, {

    shiny::showModal(
      shiny::modalDialog(
        title = "Add User",
        footer = list(
          modalButton("Cancel"),
          actionButton(
            ns("submit_user_add"),
            "Add User",
            class = "btn-success",
            icon = icon("plus"),
            style = "color: white"
          )
        ),
        size = "s",

        # modal content
        htmltools::br(),
        shiny::textInput(
          ns("user_email"),
          "Email"
        ),
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
            selected = "No",
            inline = TRUE
          ),
          htmltools::br(),
          shiny::checkboxInput(
            ns("user_include_custom_role"),
            "Custom Role",
            value = FALSE
          ),
          htmltools::br()
        ),
        shiny::selectizeInput(
          ns("user_custom_role"),
          "Role",
          choices = c(
            "",
            "Executive"
          )
        ) %>% shinyjs::hidden()
      )
    )
  })


  shiny::observeEvent(input$user_include_custom_role, {
    if (isTRUE(input$user_include_custom_role)) {
      shinyjs::show("user_custom_role", anim = TRUE)
    } else {
      shinyjs::hide("user_custom_role", anim = TRUE)
    }
  })


  users_trigger <- reactiveVal(0)
  # the firebase function to add the user is triggered in the client side js, not in Shiny
  shiny::observeEvent(input$submit_user_add, {
    shiny::removeModal()

    session$sendCustomMessage(
      "polish__add_user",
      message = list(
        email = input$user_email,
        is_admin = input$user_is_admin,
        role = if (isTRUE(input$user_include_custom_role)) input$user_custom_role else "",
        ns = ns("")
      )
    )
  })

  shiny::observeEvent(input$polish__user_add_complete, {
    users_trigger(users_trigger() + 1)
  })

  user_to_edit <- reactiveVal(NULL)
  observeEvent(input$user_row_to_edit, {
    row_num <- as.numeric(input$user_row_to_edit)
    out <- users()[row_num, ]

    user_to_edit(out)
  }, priority = 1)



  observeEvent(input$user_row_to_edit, {
    hold_user <- user_to_edit()

    shiny::showModal(
      shiny::modalDialog(
        title = "Edit User",
        footer = list(
          modalButton("Cancel"),
          actionButton(
            ns("submit_user_edit"),
            "Add User",
            class = "btn-success",
            icon = icon("plus"),
            style = "color: white"
          )
        ),
        size = "s",

        # modal content
        htmltools::br(),
        htmltools::div(
          class = "text-center",
          shiny::radioButtons(
            ns("user_is_admin_edit"),
            "Is Admin?",
            choices = c(
              "Yes",
              "No"
            ),
            selected = if (isTRUE(hold_user$is_admin)) "Yes" else "No",
            inline = TRUE
          ),
          htmltools::br(),
          shiny::checkboxInput(
            ns("user_include_custom_role_edit"),
            "Custom Role",
            value = if (hold_user$role == "") FALSE else TRUE
          ),
          htmltools::br()
        ),
        shiny::selectizeInput(
          ns("user_custom_role_edit"),
          "Role",
          choices = c(
            "",
            "Executive"
          ),
          selected = hold_user$role
        ) %>% shinyjs::hidden()
      )
    )

  })

  shiny::observeEvent(input$user_include_custom_role_edit, {
    if (isTRUE(input$user_include_custom_role_edit)) {
      shinyjs::show("user_custom_role_edit", anim = TRUE)
    } else {
      shinyjs::hide("user_custom_role_edit", anim = TRUE)
    }
  })

  shiny::observeEvent(input$submit_user_edit, {
    shiny::removeModal()

    session$sendCustomMessage(
      "polish__edit_user",
      message = list(
        email = input$user_email_edit,
        is_admin = input$user_is_admin_edit,
        role = if (isTRUE(input$user_include_custom_role_edit)) input$user_custom_role_edit else "",
        ns = ns("")
      )
    )
  })

  shiny::observeEvent(input$polish__user_edit_complete, {
    users_trigger(users_trigger() + 1)
  })


  user_to_delete <- reactiveVal(NULL)
  observeEvent(input$user_row_to_delete, {
    row_num <- as.numeric(input$user_row_to_delete)
    out <- users()[row_num, ]

    user_to_delete(out)
  }, priority = 1)



  observeEvent(input$user_row_to_delete, {
    hold_user <- user_to_delete()

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

    session$sendCustomMessage(
      "polish__delete_user",
      message = list(
        email = user_to_delete()$email,
        ns = ns("")
      )
    )
  })

  shiny::observeEvent(input$polish__user_delete_complete, {
    users_trigger(users_trigger() + 1)
  })

  shiny::observeEvent(input$manage_roles, {

    shiny::showModal(
      shiny::modalDialog(
        title = "Manage Role",
        footer = list(
          div(
            style = "height: 37px",

            div(
              id = "manage_roles_modal_footers",
              modalButton("Cancel")
            ),
            div(
              id = "delete_role_modal_footers",
              style = "display: none;",
              actionButton(
                ns("cancel_role_delete"),
                "Cancel"
              ),
              actionButton(
                ns("submit_role_delete"),
                "Delete Role",
                class = "btn-danger",
                style = "color: white",
                icon = icon("times")
              )
            )
          )
        ),
        size = "s",
        div(
          style = "min-height: 250px",
          div(
            id = "manage_roles_modal_content",
            # modal content
            htmltools::br(),
            shinyWidgets::searchInput(
              inputId = ns("new_user_role"),
              label = "New Role",
              btnSearch = icon("plus"),
              width = "100%"
            ),
            #shiny::textInput(
            #  ns("new_user_role"),
            #  "New Role"
            #),
            htmltools::br(),
            DT::DTOutput(ns("roles_table"))
          ),
          div(
            id = "delete_role_modal_content",
            style = "display: none;",
            htmltools::br(),
            h3(
              style = "line-height: 1.3;",
              'Are you sure you want to delete role "',
              tags$span(
                id = ns("role_to_delete_span")
              ),
              '"?  Any users with this role will lose it.'
            )
          )
        )
      )
    )
  })


  role_add_trigger <- reactiveVal(0)

  observeEvent(input$new_user_role_search, {
    new_role <- input$new_user_role

    if (new_role %in% roles()$role) {
      shinyjs::runjs("toastr.error('Role Already Exists')")
    } else if (new_role == "") {
      shinyjs::runjs("toastr.error('Invalid Role Name')")
    } else {
      role_add_trigger(role_add_trigger() + 1)
      print(paste0(new_role, " to be added"))
    }

  })


  observeEvent(role_add_trigger(), {

    session$sendCustomMessage(
      "polish__add_role",
      message = list(
        role = input$new_user_role
      )
    )

  }, ignoreInit = TRUE)


  roles <- reactiveVal(NULL)


  # this might be a good way to create the listener for the specific app
  #session$sendCustomMessage(
  #  "polish__create_roles_listeneer",
  #  message = list(
  #    app_name =
  #  )
  #)


  observeEvent(input$polish__user_roles, {
    if (is.null(input$polish__user_roles)) {
      out <- tibble::tibble(
        role = character(0)
      )
    } else {
      out <- tibble::tibble(
        role = input$polish__user_roles
      )
    }


    roles(out)
  }, ignoreNULL = FALSE)



  roles_table_prep <- reactive({
    req(roles())

    out <- roles()

    n_rows <- nrow(out)

    if (n_rows == 0) {
      actions <- character(0)
    } else {
      rows <- seq_len(n_rows)

      actions <- paste0(
        '<button class="btn btn-danger btn-sm delete_btn" data-toggle="tooltip" data-placement="top" title="Delete Role" id = ',
        rows,
        ' style="margin: 0"><i class="fa fa-trash-o"></i></button></div>'
      )
    }

    out <- cbind(
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
          list(targets = 0, class = "dt-center"),
          list(targets = 0, width = "35px")
        )
      )
    )
  })




  role_to_delete <- reactiveVal(NULL)

  observeEvent(input$role_row_to_delete, {
    row_num <- as.numeric(input$role_row_to_delete)
    out <- roles()[row_num, ]$role

    role_to_delete(out)
  }, priority = 1)

  observeEvent(input$role_row_to_delete, {
    hold_role <- role_to_delete()

    shinyjs::runjs("$('#manage_roles_modal_content').hide()")
    shinyjs::runjs("$('#manage_roles_modal_footers').hide()")
    shinyjs::runjs("$('#delete_role_modal_content').show('slide', {direction: 'right'}, 400)")
    shinyjs::runjs("$('#delete_role_modal_footers').show('slide', {direction: 'right'}, 400)")
    #shinyjs::hide("manage_roles_modal_content")
    #shinyjs::show("delete_role_modal_content", anim = TRUE)
    print(list("role_to_delete" = hold_role))
  })

  observeEvent(input$cancel_role_delete, {

    shinyjs::runjs("$('#delete_role_modal_content').hide()")
    shinyjs::runjs("$('#delete_role_modal_footers').hide()")
    shinyjs::runjs("$('#manage_roles_modal_content').show('slide', {direction: 'left'}, 400)")
    shinyjs::runjs("$('#manage_roles_modal_footers').show('slide', {direction: 'left'}, 400)")
  })

  observeEvent(role_to_delete(), {
    shinyjs::html("role_to_delete_span", html = role_to_delete())
  })


  shiny::observeEvent(input$submit_role_delete, {
    shiny::removeModal()

    session$sendCustomMessage(
      "polish__delete_role",
      message = list(
        role = role_to_delete()
      )
    )
  })

}
