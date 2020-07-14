#' UI for the sign in and register pages
#'
#' UI for the sign in and register pages when a user invite is required to register and
#' sign in.  See \code{\link{sign_in_no_invite_module}} if you do not require your
#' users to sign in and register to access your 'shiny' app.
#'
#' @param id the Shiny module id
#' @param register_link The text that will be displayed in the link to go to the
#' user registration page.  The default is "First time user? Register here!".
#' Set to \code{NULL} if you don't want to use the registration page.
#'
#' @importFrom shiny textInput actionButton NS actionLink
#' @importFrom htmltools tagList tags div h1 br hr
#' @importFrom shinyFeedback useShinyFeedback
#' @importFrom shinyjs useShinyjs hidden
#'
#' @export
#'
#'
sign_in_module_ui <- function(
  id,
  register_link = "First time user? Register here!"
) {
  ns <- shiny::NS(id)

  providers <- .global_sessions$sign_in_providers

  continue_sign_in <- div(
    id = ns("continue_sign_in"),
    shiny::actionButton(
      inputId = ns("submit_continue_sign_in"),
      label = "Continue",
      width = "100%",
      class = "btn btn-primary btn-lg"
    )
  )

  sign_in_password <- div(
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
    shinyFeedback::loadingButton(
      ns("submit_sign_in"),
      label = "Sign In",
      class = "btn btn-primary btn-lg text-center",
      style = "width: 100%",
      loadingLabel = "Authenticating...",
      loadingClass = "btn btn-primary btn-lg text-center",
      loadingStyle = "width: 100%"
    )
  )

  continue_registration <- div(
    id = ns("continue_registration"),
    shiny::actionButton(
      inputId = ns("submit_continue_register"),
      label = "Continue",
      width = "100%",
      class = "btn btn-primary btn-lg"
    )
  )

  register_passwords <- div(
    id = ns("register_passwords"),
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
      shinyFeedback::loadingButton(
        ns("submit_register"),
        label = "Register",
        class = "btn btn-primary btn-lg",
        style = "width: 100%;",
        loadingLabel = "Registering...",
        loadingClass = "btn btn-primary btn-lg text-center",
        loadingStyle = "width: 100%;"
      )
    )
  )

  email_ui <- tags$div(
    id = ns("email_ui"),
    tags$div(
      id = ns("sign_in_panel_top"),
      htmltools::h1(
        class = "text-center",
        style = "padding-top: 0;",
        "Sign In"
      ),
      tags$br(),
      email_input(
        inputId = ns("email"),
        label = tagList(icon("envelope"), "email"),
        value = ""
      ),
      tags$br()
    ),
    tags$div(
      id = ns("sign_in_panel_bottom"),
      if (isTRUE(.global_sessions$is_invite_required)) {
        tagList(continue_sign_in, shinyjs::hidden(sign_in_password))
      } else {
        sign_in_password
      },
      div(
        style = "text-align: center;",
        if (is.null(register_link)) {
          list()
        } else {
          list(
            hr(),
            shiny::actionLink(
              inputId = ns("go_to_register"),
              label = register_link
            )
          )
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
      id = ns("register_panel_top"),
      h1(
        class = "text-center",
        style = "padding-top: 0;",
        "Register"
      ),
      tags$br(),
      email_input(
        inputId = ns("email_register"),
        label = tagList(icon("envelope"), "email"),
        value = ""
      ),
      tags$br()
    )),

    shinyjs::hidden(div(
      id = ns("register_panel_bottom"),
      if (isTRUE(.global_sessions$is_invite_required)) {
        tagList(continue_registration, shinyjs::hidden(register_passwords))
      } else {
        register_passwords
      },
      div(
        style = "text-align: center",
        hr(),
        shiny::actionLink(
          inputId = ns("go_to_sign_in"),
          label = "Already a user? Sign in!"
        ),
        br(),
        br()
      )
    ))
  )

  if (length(providers) == 1 && providers == "email") {
    ui_out <- email_ui
  } else {

    hold_providers_ui <- providers_ui(
      ns,
      providers
    )

    email_ui <- shinyjs::hidden(email_ui)

    ui_out <-  tagList(
      hold_providers_ui,
      email_ui
    )

  }



  htmltools::tagList(
    shinyjs::useShinyjs(),
    tags$div(
      class = "auth_panel",
      ui_out
    ),
    tags$script(src = "polish/js/auth_keypress.js"),
    tags$script(paste0("auth_keypress('", ns(''), "')")),
    sign_in_js(ns)
  )
}

#' Server logic for the sign in and register pages
#'
#' This server logic accompanies the \code{\link{sign_in_module_ui}}.
#'
#' @param input the Shiny input
#' @param output the Shiny output
#' @param session the Shiny session
#'
#' @importFrom shiny observeEvent observe getQueryString updateTextInput
#' @importFrom shinyjs show hide
#' @importFrom shinyWidgets sendSweetAlert
#' @importFrom digest digest
#'
#' @export
#'
sign_in_module <- function(input, output, session) {
  ns <- session$ns


  observeEvent(input$sign_in_with_email, {
    shinyjs::show("email_ui")
    shinyjs::hide("providers_ui")
  })


  go_to_registration_page <- function() {
    # go to the user registration page
    shinyjs::hide("sign_in_panel_top")
    shinyjs::hide("sign_in_panel_bottom")
    shinyjs::show("register_panel_top")
    shinyjs::show("register_panel_bottom")
  }

  # if query parameter "register" == TRUE, then go directly to registration page
  observe({
    query_string <- shiny::getQueryString()

    if (identical(query_string$register, "TRUE")) {
      go_to_registration_page()
    }
  })


  shiny::observeEvent(input$submit_continue_sign_in, {

    email <- tolower(input$email)

    # check user invite
    invite <- NULL
    tryCatch({

      invite <- .global_sessions$get_invite_by_email(email)

      if (is.null(invite)) {

        shinyWidgets::sendSweetAlert(
          session,
          title = "Not Authorized",
          text = "You must have an invite to access this app",
          type = "error"
        )
        return()
      } else {

        # check is user is already registered with Firebase.  If user already registered,
        # then allow them to continue signing in.  If not registered, take the user
        # to the registration page and open the passwords to continue registration.

        # this custom message triggers the `input$check_registered_res` input which
        # will fire off the next observeEvent
        session$sendCustomMessage(
          session$ns("check_registered"),
          message = list(
            email = email
          )
        )

      }


    }, error = function(e) {
      # user is not invited
      print(e)
      shinyWidgets::sendSweetAlert(
        session,
        title = "Error",
        text = "Error checking invite",
        type = "error"
      )

    })

  })


  observeEvent(input$check_registered_res, {
    hold_email <- tolower(input$email)

    is_registered <- input$check_registered_res

    if (isTRUE(is_registered)) {
      # user is already registered, so continue sign in
      # user is invited
      shinyjs::hide("submit_continue_sign_in")

      shinyjs::show(
        "sign_in_password",
        anim = TRUE
      )

      # NEED to sleep this exact amount to allow animation (above) to show w/o bug
      Sys.sleep(.25)

      shinyjs::runjs(paste0("$('#", ns('password'), "').focus()"))

    } else if (isFALSE(is_registered)) {

      # go to the user registration page
      go_to_registration_page()

      shiny::updateTextInput(
        session,
        "email_register",
        value = hold_email
      )

      # user is invited
      shinyjs::hide("continue_registration")

      shinyjs::show(
        "register_passwords",
        anim = TRUE
      )

      # NEED to sleep this exact amount to allow animation (above) to show w/o bug
      Sys.sleep(.25)

      shinyjs::runjs(paste0("$('#", ns('register_password'), "').focus()"))


    } else {

      print(is_registered)
      shinyWidgets::sendSweetAlert(
        session,
        title = "Error",
        text = "Error checking invite",
        type = "error"
      )
    }
  })


  shiny::observeEvent(input$go_to_register, {
    go_to_registration_page()
  })

  shiny::observeEvent(input$go_to_sign_in, {
    shinyjs::hide("register_panel_top")
    shinyjs::hide("register_panel_bottom")
    shinyjs::show("sign_in_panel_top")
    shinyjs::show("sign_in_panel_bottom")
  })





  submit_continue_register_rv <- reactiveVal(0)

  observeEvent(input$submit_continue_register, {
    submit_continue_register_rv(submit_continue_register_rv() + 1)
  })

  shiny::observeEvent(submit_continue_register_rv(), {

    email <- tolower(input$email_register)

    invite <- NULL
    tryCatch({
      invite <- .global_sessions$get_invite_by_email(email)

      if (is.null(invite)) {

        shinyWidgets::sendSweetAlert(
          session,
          title = "Not Authorized",
          text = "You must have an invite to access this app",
          type = "error"
        )
        return()
      }

      # user is invited
      shinyjs::hide("continue_registration")

      shinyjs::show(
        "register_passwords",
        anim = TRUE
      )

      # NEED to sleep this exact amount to allow animation (above) to show w/o bug
      Sys.sleep(.25)

      shinyjs::runjs(paste0("$('#", ns('register_password'), "').focus()"))

    }, error = function(e) {
      # user is not invited
      print(e)
      shinyWidgets::sendSweetAlert(
        session,
        title = "Error",
        text = "Error checking invite",
        type = "error"
      )
    })

  }, ignoreInit = TRUE)


  sign_in_check_jwt(
    jwt = shiny::reactive({input$check_jwt})
  )

  invisible()
}
