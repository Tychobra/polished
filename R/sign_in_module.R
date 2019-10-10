#' sign_in_module_ui
#'
#' UI for the sign in and register panels
#'
#' @param id the Shiny module id
#' @param firebase_config list of Firebase config
#'
#' @importFrom shiny textInput actionButton NS actionLink
#' @importFrom htmltools tagList tags div h1 br
#' @importFrom shinytoastr useToastr
#' @importFrom shinyjs useShinyjs hidden
#'
#' @export
#'
#'
sign_in_module_ui <- function(id, firebase_config) {
  ns <- shiny::NS(id)

  htmltools::tagList(
    tags$head(
      tags$link(rel = "shortcut icon", href = "polish/images/tychobra-icon-blue.png"),
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/css/toastr.min.css")
    ),
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
      shiny::textInput(
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
            value = "",
            placeholder = "**********"
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
        hr(),
        br(),
        shiny::actionLink(
          inputId = ns("go_to_register"),
          label = "Not a member? Register!"
        ),
        br(),
        br(),
        tags$a(
          id = ns("reset_password"),
          href = "#",
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
        textInput(
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
            value = "",
            placeholder = "**********"
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
            value = "",
            placeholder = "**********"
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
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/js/toastr.min.js"),
    firebase_dependencies(),
    firebase_init(firebase_config),
    tags$script(src = "polish/js/loading_options.js"),
    tags$script(src = "polish/js/toast_options.js"),
    tags$script(src = "polish/js/auth_all.js"),
    tags$script(paste0("auth_all('", id, "')")),
    tags$script(src = "polish/js/auth_firebase.js"),
    tags$script(paste0("auth_firebase('", id, "')")),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js")
  )
}

#' sign_in
#'
#' @param input the Shiny input
#' @param output the Shiny output
#' @param session the Shiny session
#' @param conn a database connection
#'
#' @importFrom shiny observeEvent
#' @importFrom tychobratools show_toast
#' @importFrom shinyjs show hide
#' @importFrom shinyWidgets sendSweetAlert
#'
sign_in_module <- function(input, output, session) {

  ns <- session$ns

  shiny::observeEvent(input$polished__sign_in, {
    firebase_token <- input$polished__sign_in$firebase_token
    polished_token <- input$polished__sign_in$polished_token


    session$sendCustomMessage(
      "polish__show_loading",
      message = list(
        text = "Loading..."
      )
    )

    # attempt to sign in
    new_user <- .global_sessions$sign_in(session$userData$pcon, firebase_token)

    if (is.null(new_user)) {
      # user sign in failed.

      session$sendCustomMessage(
        "polish__remove_loading",
        message = list()
      )

      tychobratools::show_toast("error", "Error signing into polished server")

    } else {
      # go to app.  If user is admin, then they will have the blue "Admin Panel" button
      # in the bottom right

      # send cookie to front end, wait for confirmation that cookie is set, and then reload session
      session$sendCustomMessage(
        ns("polished__set_cookie"),
        message = list(
          polished_token = new_user$token
        )
      )

      # wait for the cookie to be set, and then reload the session
      observeEvent(input$polished__set_cookie_complete, {
        session$reload()
      }, once = TRUE)

    }
  }, ignoreInit = TRUE)


  shiny::observeEvent(input$submit_continue_sign_in, {

    email <- input$email

    # check user invite
    invite <- NULL
    tryCatch({
      invite <- .global_sessions$get_invite(session$userData$pcon, email)

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

    email <- input$register_email

    invite <- NULL
    tryCatch({
      invite <- .global_sessions$get_invite(session$userData$pcon, email)

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
}
