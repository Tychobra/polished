#' UI for the Sign In & Register pages
#'
#' UI for the Sign In & Register pages when a user invite is required to Register & Sign In.
#'
#' @param id the Shiny module \code{id}
#' @param register_link The text that will be displayed in the link to go to the
#' user registration page.  The default is \code{"First time user? Register here!"}.
#' Set to \code{NULL} if you don't want to use the registration page.
#'
#' @importFrom shiny textInput actionButton NS actionLink
#' @importFrom htmltools tagList tags div h1 br hr
#' @importFrom shinyFeedback useShinyFeedback loadingButton
#' @importFrom shinyjs useShinyjs hidden disabled
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
    ) %>% shinyjs::disabled()
  )

  sign_in_password_ui <- div(
    id = ns("sign_in_password_ui"),
    div(
      class = "form-group",
      style = "width: 100%;",
      tags$label(
        tagList(icon("unlock-alt"), "password"),
        `for` = "sign_in_password"
      ),
      tags$input(
        id = ns("sign_in_password"),
        type = "password",
        class = "form-control",
        value = ""
      )
    ),
    br(),
    shinyFeedback::loadingButton(
      ns("sign_in_submit"),
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
    div(
      style = "text-align: center;",
      shinyFeedback::loadingButton(
        ns("register_submit"),
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
        inputId = ns("sign_in_email"),
        label = tagList(icon("envelope"), "email"),
        value = ""
      ),
      tags$br()
    ),
    tags$div(
      id = ns("sign_in_panel_bottom"),
      if (isTRUE(.global_sessions$is_invite_required)) {
        tagList(continue_sign_in, shinyjs::hidden(sign_in_password_ui))
      } else {
        sign_in_password_ui
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
        send_password_reset_email_module_ui(ns("reset_password"))
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
        inputId = ns("register_email"),
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

    ui_out <- tagList(
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
    tags$script(src = "polish/js/auth_keypress.js?version=4"),
    tags$script(paste0("auth_keypress('", ns(''), "')")),
    tags$script(
      "$('input').attr('autocomplete', 'off');"
    ),
    sign_in_js(ns)
  )
}

#' Server logic for the Sign In & Register pages
#'
#' This server logic accompanies the \code{\link{sign_in_module_ui}}.
#'
#' @param input the Shiny \code{input}
#' @param output the Shiny \code{output}
#' @param session the Shiny \code{session}
#'
#' @importFrom shiny observeEvent observe getQueryString updateTextInput
#' @importFrom shinyjs show hide enable disable
#' @importFrom shinyWidgets sendSweetAlert
#' @importFrom shinyFeedback showToast hideFeedback showFeedbackDanger resetLoadingButton
#' @importFrom digest digest
#' @importFrom httr POST authenticate
#'
#' @export
#'
sign_in_module <- function(input, output, session) {
  ns <- session$ns

  # Email Sign-In validation
  observeEvent(input$sign_in_email, {
    if (input$sign_in_email == "") {
      shinyjs::disable("submit_continue_sign_in")
      shinyFeedback::hideFeedback("sign_in_email")
    } else if (is_valid_email(input$sign_in_email)) {
      shinyFeedback::hideFeedback("sign_in_email")
      shinyjs::enable("submit_continue_sign_in")
    } else {
      shinyjs::disable("submit_continue_sign_in")
      shinyFeedback::showFeedbackDanger(
        "sign_in_email",
        "Invalid Email"
      )
    }
  })

  # Email Registration validation
  observeEvent(input$register_email, {
    if (input$register_email == "") {
      shinyjs::disable("submit_continue_register")
      shinyFeedback::hideFeedback("register_email")
    } else if (is_valid_email(input$register_email)) {
      shinyFeedback::hideFeedback("register_email")
      shinyjs::enable("submit_continue_register")
    } else {
      shinyjs::disable("submit_continue_register")
      shinyFeedback::showFeedbackDanger(
        "register_email",
        "Invalid Email"
      )
    }
  })

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

  shiny::observeEvent(input$go_to_register, {
    go_to_registration_page()
  })

  shiny::callModule(
    send_password_reset_email_module,
    "reset_password",
    email = reactive({input$sign_in_email})
  )


  # if query parameter "register" == TRUE, then go directly to registration page
  observe({
    query_string <- shiny::getQueryString()

    if (identical(query_string$register, "TRUE")) {
      go_to_registration_page()
    }
  })


  shiny::observeEvent(input$submit_continue_sign_in, {

    email <- tolower(input$sign_in_email)

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

      } else {


        # user is invited, so continue the sign in process
        shinyjs::hide("submit_continue_sign_in")

        shinyjs::show(
          "sign_in_password_ui",
          anim = TRUE
        )

        # NEED to sleep this exact amount to allow animation (above) to show w/o bug
        Sys.sleep(.25)

        shinyjs::runjs(paste0("$('#", ns('sign_in_password'), "').focus()"))

      }

    }, error = function(err) {
      # user is not invited
      print(err)
      shinyWidgets::sendSweetAlert(
        session,
        title = "Error",
        text = err$message,
        type = "error"
      )

    })

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

    email <- tolower(input$register_email)

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


  observeEvent(input$register_js, {
    hold_email <- input$register_js$email
    hold_password <- input$register_js$password
    cookie <- input$register_js$cookie

    hashed_cookie <- digest::digest(cookie)


    tryCatch({
      .global_sessions$register_email(
        hold_email,
        hold_password,
        hashed_cookie
      )

      remove_query_string()
      session$reload()
    }, error = function(err) {

      shinyFeedback::resetLoadingButton('register_submit')

      print(err)
      shinyFeedback::showToast(
        "error",
        err$message,
        .options = polished_toast_options
      )
    })

  })

  sign_in_check_jwt(
    jwt = shiny::reactive({input$check_jwt})
  )

  invisible()
}
