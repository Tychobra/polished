#' sign_in_no_invite_module_ui
#'
#' UI for the sign in and register panels.  User is not required to have an invite
#' to sign in and register.
#'
#' @param id the Shiny module id
#'
#' @importFrom shiny textInput actionButton NS actionLink
#' @importFrom htmltools tagList tags div h1 br hr
#' @importFrom shinytoastr useToastr
#' @importFrom shinyjs useShinyjs
#'
#' @export
#'
#'
sign_in_no_invite_module_ui <- function(id) {
  ns <- shiny::NS(id)

  firebase_config <- .global_sessions$firebase_config

  fluidPage(
    fluidRow(
      shinyjs::useShinyjs(),
      shinytoastr::useToastr(),
      shiny::div(
        id = ns("sign_in_panel"),
        class = "auth_panel",
        htmltools::h1(
          class = "text-center",
          style = "padding-top: 0;",
          "Sign In"
        ),
        br(),
        email_input(
          inputId = ns("email"),
          label = tagList(icon("envelope"), "email"),
          value = ""
        ),
        br(),
        div(
          id = ns("sign_in_password"),
          div(
            class = "form-group",
            style = "width: 100%;",
            tags$label(
              tagList(icon("unlock-alt"), "password"),
              `for` = "password"
            ),
            tags$input(
              id = ns("password"),
              type = "password",
              class = "form-control",
              value = ""
            )
          ),
          br(),
          tychobratools::loading_button(
            ns("submit_sign_in"),
            label = "Sign In",
            class = "btn btn-primary btn-lg text-center",
            style = "",
            loading_label = "Authenticating...",
            loading_class = "btn btn-primary btn-lg text-center",
            loading_style = ""
          )
        ),
        div(
          style = "text-align: center;",
          hr(),
          br(),
          shiny::actionLink(
            inputId = ns("go_to_register"),
            label = "Not a member? Register!"
          ),
          br(),
          br(),
          tags$button(
            class = 'btn btn-link btn-small',
            id = ns("reset_password"),
            "Forgot your password?"
          )
        )
      ),



      hidden(div(
        id = ns("register_panel"),
        class = "auth_panel",
        h1(
          class = "text-center",
          style = "padding-top: 0;",
          "Register"
        ),
        br(),
        div(
          class = "form-group",
          style = "width: 100%",
          email_input(
            inputId = ns("register_email"),
            label = tagList(shiny::icon("envelope"), "email"),
            value = ""
          )
        ),
        div(
          id = ns("register_passwords"),
          br(),
          div(
            class = "form-group",
            style = "width: 100%",
            tags$label(
              tagList(icon("unlock-alt"), "password"),
              `for` = ns("register_password")
            ),
            tags$input(
              id = ns("register_password"),
              type = "password",
              class = "form-control",
              value = ""
            )
          ),
          br(),
          div(
            class = "form-group shiny-input-container",
            style = "width: 100%",
            tags$label(
              tagList(shiny::icon("unlock-alt"), "verify password"),
              `for` = ns("register_password_verify")
            ),
            tags$input(
              id = ns("register_password_verify"),
              type = "password",
              class = "form-control",
              value = ""
            )
          ),
          br(),
          br(),
          div(
            style = "text-align: center;",
            tychobratools::loading_button(
              ns("submit_register"),
              label = "Register",
              class = "btn btn-primary btn-lg",
              style = "",
              loading_label = "Registering...",
              loading_class = "btn btn-primary btn-lg text-center",
              loading_style = ""
            )
          )
        ),
        div(
          style = "text-align: center",
          hr(),
          br(),
          shiny::actionLink(
            inputId = ns("go_to_sign_in"),
            label = "Already a member? Sign in!"
          ),
          br(),
          br()
        )
      )
    )),

    firebase_dependencies(),
    firebase_init(firebase_config),
    tags$script(src = "polish/js/toast_options.js"),
    tags$script(src = "polish/js/auth_all_no_invite.js"),
    tags$script(paste0("auth_all_no_invite('", ns(''), "')")),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    tags$script(src = "polish/js/auth_firebase.js?version=2"),
    tags$script(paste0("auth_firebase('", ns(''), "')"))
  )
}

#' sign_in_no_invite_module
#'
#' @param input the Shiny input
#' @param output the Shiny output
#' @param session the Shiny session
#'
#' @importFrom shiny observeEvent
#' @importFrom tychobratools show_toast reset_loading_button
#' @importFrom shinyjs show hide
#' @importFrom shinyWidgets sendSweetAlert
#' @importFrom digest digest
#'
sign_in_no_invite_module <- function(input, output, session) {
  ns <- session$ns

  shiny::observeEvent(input$go_to_register, {
    shinyjs::hide("sign_in_panel")
    shinyjs::show("register_panel")
  })

  shiny::observeEvent(input$go_to_sign_in, {
    shinyjs::hide("register_panel")
    shinyjs::show("sign_in_panel")
  })


  observeEvent(input$check_jwt, {

    tryCatch({

      # user is invited, so attempt sign in
      new_user <- .global_sessions$sign_in(
        input$check_jwt$jwt,
        digest::digest(input$check_jwt$cookie)
      )

      if (is.null(new_user)) {
        tychobratools::reset_loading_button('submit_sign_in')
        # show unable to sign in message
        tychobratools::show_toast('error', 'sign in error')
        stop('sign_in_module: sign in error')

      } else {
        # sign in success
        remove_query_string()
        session$reload()
      }



    }, error = function(e) {
      tychobratools::reset_loading_button('submit_sign_in')
      # user is not invited
      print(e)
      shinyWidgets::sendSweetAlert(
        session,
        title = "Not Authorized",
        text = "You must have an invite to access this app",
        type = "error"
      )

    })

  })
}
