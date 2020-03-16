#' sign_in_module_ui
#'
#' UI for the sign in and register panels
#'
#' @param id the Shiny module id
#' @param firebase_config list of Firebase config
#' @param allow_register default is `TRUE`.  Whether or not to show the
#' "Not a Member? Register!" link.  This should only be set to `FALSE` if
#' you are handling Firebase registration yourself e.g. your are automatically
#' registering users via Firebase Admin or you are manually registering users
#' via your Firebase project's web console.
#'
#' @importFrom shiny textInput actionButton NS actionLink
#' @importFrom htmltools tagList tags div h1 br hr
#' @importFrom shinytoastr useToastr
#' @importFrom shinyjs useShinyjs hidden
#'
#' @export
#'
#'
sign_in_module_ui <- function(id, firebase_config, allow_register = TRUE) {
  ns <- shiny::NS(id)

  htmltools::tagList(
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
      shinyjs::hidden(div(
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
        shiny::actionButton(
          inputId = ns("submit_sign_in"),
          label = "Sign In",
          class = "text-center",
          style = "color: white; width: 100%;",
          class = "btn btn-primary btn-lg"
        )
      )),
      div(
        id = ns("continue_sign_in"),
        shiny::actionButton(
          inputId = ns("submit_continue_sign_in"),
          label = "Continue",
          style = "color: white; width: 100%;",
          class = "btn btn-primary btn-lg"
        )
      ),
      div(
        style = "text-align: center;",
        if (allow_register) {
          list(
            hr(),
            br(),
            shiny::actionLink(
              inputId = ns("go_to_register"),
              label = "Not a member? Register!"
            ),
            br()
          )
        } else {
          list()
        },
        br(),
        tags$button(
          class = 'btn btn-link btn-small',
          id = ns("reset_password"),
          "Forgot your password?"
        )
      )
    ),



    shinyjs::hidden(div(
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
        id = ns("continue_registation"),
        br(),
        shiny::actionButton(
          inputId = ns("submit_continue_register"),
          label = "Continue",
          style = "color: white; width: 100%;",
          class = "btn btn-primary btn-lg"
        )
      ),
      shinyjs::hidden(div(
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
          actionButton(
            inputId = ns("submit_register"),
            label = "Register",
            style = "color: white; width: 100%;",
            class = "btn btn-primary btn-lg"
          )
        )
      )),
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
    )),

    tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
    firebase_dependencies(),
    firebase_init(firebase_config),
    tags$script(src = "polish/js/loading_options.js"),
    tags$script(src = "polish/js/toast_options.js"),
    tags$script(src = "polish/js/auth_all.js"),
    tags$script(paste0("auth_all('", ns(''), "')")),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    tags$script(src = "polish/js/auth_firebase.js?version=2"),
    tags$script(paste0("auth_firebase('", ns(''), "')"))
  )
}

#' sign_in
#'
#' @param input the Shiny input
#' @param output the Shiny output
#' @param session the Shiny session
#'
#' @importFrom shiny observeEvent
#' @importFrom tychobratools show_toast
#' @importFrom shinyjs show hide
#' @importFrom shinyWidgets sendSweetAlert
#' @importFrom digest digest
#'
sign_in_module <- function(input, output, session) {
  ns <- session$ns

  email_rv <- reactiveVal("")

  shiny::observeEvent(input$submit_continue_sign_in, {

    email <- tolower(input$email)
    email_rv(email)

    # check user invite
    invite <- NULL
    tryCatch({
      invite <- .global_sessions$get_invite_by_email(email)

      # user is invited
      shinyjs::hide("submit_continue_sign_in")

      shinyjs::show(
        "sign_in_password",
        anim = TRUE
      )
    }, error = function(e) {
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

  shiny::observeEvent(input$go_to_register, {
    shinyjs::hide("sign_in_panel")
    shinyjs::show("register_panel")
  })

  shiny::observeEvent(input$go_to_sign_in, {
    shinyjs::hide("register_panel")
    shinyjs::show("sign_in_panel")
  })







  shiny::observeEvent(input$submit_continue_register, {

    email <- tolower(input$register_email)
    email_rv(email)
    invite <- NULL
    tryCatch({
      invite <- .global_sessions$get_invite_by_email(email)

      # user is invited
      shinyjs::hide("continue_registation")

      shinyjs::show(
        "register_passwords",
        anim = TRUE
      )
    }, error = function(e) {
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

  observeEvent(input$check_jwt, {
    email <- email_rv()

    tryCatch({
      invite <- .global_sessions$get_invite_by_email(email)

      # user is invited, so attempt sign in
      new_user <- .global_sessions$sign_in(
        input$check_jwt$jwt,
        digest::digest(input$check_jwt$cookie)
      )


      if (is.null(new_user)) {
        # show unable to sign in message
        tychobratools::show_toast('error', 'sign in error')
        stop('sign_in_module: sign in error')

      } else {
        # sign in success
        remove_query_string()
        session$reload()
      }



    }, error = function(e) {
      # user is not invited
      session$sendCustomMessage(
        ns('remove_loading'),
        message = list()
      )
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
