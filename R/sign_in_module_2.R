#' UI for the Sign In & Register pages
#'
#' Alternate sign in UI that works regardless of whether or not invites
#' are required. The UI displays email sign in inputs on the left, and social sign in options
#' on the right.  \code{\link{sign_in_module_2}} must be provided as the
#' argument \code{custom_sign_in_server} in \code{\link{secure_server}} for proper
#' functionality.
#'
#' @param id the Shiny module \code{id}
#'
#' @importFrom shiny textInput actionButton NS actionLink icon
#' @importFrom htmltools tagList tags
#' @importFrom shinyFeedback useShinyFeedback loadingButton
#' @importFrom shinyjs useShinyjs hidden disabled
#'
#' @export
#'
#'
sign_in_module_2_ui <- function(id) {
  ns <- shiny::NS(id)

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

  continue_sign_in <- div(
    id = ns("continue_sign_in"),
    shiny::actionButton(
      inputId = ns("submit_continue_sign_in"),
      label = "Continue",
      width = "100%",
      class = "btn btn-primary btn-lg"
    )
  )

  sign_in_email_ui <- tags$div(
    id = ns("email_ui"),
    tags$br(),
    email_input(
      inputId = ns("sign_in_email"),
      label = tagList(icon("envelope"), "email"),
      value = "",
      width = "100%"
    ),
    tags$div(
      id = ns("sign_in_panel_bottom"),
      if (isTRUE(.polished$is_invite_required)) {
        tagList(continue_sign_in, shinyjs::hidden(sign_in_password_ui))
      } else {
        sign_in_password_ui
      },
      div(
        style = "text-align: center;",
        br(),
        send_password_reset_email_module_ui(ns("reset_password"))
      )
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
      ),
      br(),
      br()
    )
  )

  register_ui <- div(
    br(),
    email_input(
      inputId = ns("register_email"),
      label = tagList(icon("envelope"), "email"),
      value = "",
      width = "100%"
    ),
    if (isTRUE(.polished$is_invite_required)) {
      tagList(continue_registration, shinyjs::hidden(register_passwords))
    } else {
      register_passwords
    }
  )

  sign_in_register_email <- shiny::tabsetPanel(
    id = ns("tabs"),
    shiny::tabPanel("Sign In", sign_in_email_ui),
    shiny::tabPanel("Register", register_ui)
  )

  providers <- .polished$sign_in_providers

  if (length(providers) == 1 && providers == "email") {
    sign_in_ui <- tags$div(
      class = "auth_panel",
      sign_in_register_email
    )
  } else {

    hold_providers_ui <- providers_ui(
      ns,
      providers[providers != "email"],
      title = NULL,
      fancy = FALSE
    )

    sign_in_ui <- tags$div(
      class = "auth_panel_2",
      fluidRow(
        column(
          7,
          style = "border-style: none solid none none; border-width: 1px; border-color: #ddd;",
          sign_in_register_email
        ),
        column(
          5,
          br(),
          br(),
          br(),
          br(),
          div(
            style = "margin-top: 8px;",
            hold_providers_ui
          )
        )
      )
    )
  }



  htmltools::tagList(
    shinyjs::useShinyjs(),
    sign_in_ui,
    tags$script(src = "polish/js/auth_keypress.js?version=2"),
    tags$script(paste0("auth_keypress('", ns(''), "')")),
    tags$script(
      "$('input').attr('autocomplete', 'off');"
    ),
    sign_in_js(ns)
  )
}

#' Server logic for the Sign In & Register pages
#'
#' This server logic accompanies \code{\link{sign_in_module_2_ui}}.
#'
#' @param input the Shiny \code{input}
#' @param output the Shiny \code{output}
#' @param session the Shiny \code{session}
#'
#' @importFrom shiny observeEvent observe getQueryString updateTabsetPanel updateTextInput isolate
#' @importFrom shinyjs show hide disable
#' @importFrom shinyWidgets sendSweetAlert
#' @importFrom digest digest
#' @importFrom shinyFeedback hideFeedback showFeedbackDanger resetLoadingButton
#'
#' @export
#'
sign_in_module_2 <- function(input, output, session) {
  ns <- session$ns

  # Email Sign-In validation
  observeEvent(input$sign_in_email, {
    shinyFeedback::hideFeedback("sign_in_email")
  })

  # Email Registration validation
  observeEvent(input$register_email, {
    shinyFeedback::hideFeedback("register_email")
  })

  observeEvent(input$sign_in_with_email, {
    shinyjs::show("email_ui")
    shinyjs::hide("providers_ui")
  })



  observe({
    query_string <- shiny::getQueryString()

    if (identical(query_string$register, "TRUE")) {
      shiny::updateTabsetPanel(
        session,
        "tabs",
        selected = "Register"
      )
    }
  })

  shiny::callModule(
    send_password_reset_email_module,
    "reset_password",
    email = reactive({input$sign_in_email})
  )

  shiny::observeEvent(input$submit_continue_sign_in, {

    email <- tolower(input$sign_in_email)

    if (!is_valid_email(email)) {
      shinyFeedback::showFeedbackDanger(
        "sign_in_email",
        text = "Invalid email"
      )
      return()
    }

    # check user invite
    invite <- NULL
    tryCatch({

      invite_res <- get_app_users(
        app_uid = .polished$app_uid,
        email = email
      )

      invite <- invite_res$content

      if (!identical(nrow(invite), 1L)) {

        shinyWidgets::sendSweetAlert(
          session,
          title = "Not Authorized",
          text = "You must have an invite to access this app",
          type = "error"
        )
        return()
      } else {

        if (is_email_registered(email)) {

          # user is invited, so continue the sign in process
          shinyjs::hide("submit_continue_sign_in")

          shinyjs::show(
            "sign_in_password_ui",
            anim = TRUE
          )

          # NEED to sleep this exact amount to allow animation (above) to show w/o bug
          Sys.sleep(.25)

          shinyjs::runjs(paste0("$('#", ns('sign_in_password'), "').focus()"))


        } else {

          # user is not registered (they are accidentally attempting to sign in before
          # they have registed), so send them to the registration page and auto populate
          # the registration email input
          shiny::updateTabsetPanel(
            session,
            "tabs",
            "Register"
          )

          shiny::updateTextInput(
            session,
            "register_email",
            value = email
          )

          shinyjs::hide("continue_registration")

          shinyjs::show(
            "register_passwords",
            anim = TRUE
          )

          # NEED to sleep this exact amount to allow animation (above) to show w/o bug
          Sys.sleep(0.3)

          shinyjs::runjs(paste0("$('#", ns('register_password'), "').focus()"))
        }

      }


    }, error = function(err) {
      # user is not invited
      print("Error in continuing sign in")
      print(err)
      shinyWidgets::sendSweetAlert(
        session,
        title = "Error",
        text = err$message,
        type = "error"
      )

    })

  })




  shiny::observeEvent(input$submit_continue_register, {

    email <- tolower(input$register_email)

    if (!is_valid_email(email)) {
      shinyFeedback::showFeedbackDanger(
        "register_email",
        text = "Invalid email"
      )
      return()
    }

    invite <- NULL
    tryCatch({

      invite_res <- get_app_users(
        app_uid = .polished$app_uid,
        email = email
      )

      invite <- invite_res$content

      if (!identical(nrow(invite), 1L)) {

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
      print("Error in continuing registration")
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

    is_email <- is.null(input$check_jwt$jwt)
    if (isTRUE(is_email) && !is_valid_email(hold_email)) {

      shinyFeedback::showFeedbackDanger(
        "register_email",
        text = "Invalid email"
      )
      shinyFeedback::resetLoadingButton("register_submit")
      return(NULL)

    }

    hashed_cookie <- digest::digest(cookie)


    tryCatch({
      register_email(
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

  check_jwt_email_valid <- reactive({
    req(input$check_jwt)

    is_email <- is.null(input$check_jwt$jwt)
    if (isTRUE(is_email) && !is_valid_email(isolate({input$sign_in_email}))) {

      shinyFeedback::showFeedbackDanger(
        "sign_in_email",
        text = "Invalid email"
      )
      shinyFeedback::resetLoadingButton("sign_in_submit")
      return(NULL)
    }

    input$check_jwt
  })

  sign_in_check_jwt(
    jwt = shiny::reactive({
      check_jwt_email_valid()
    })
  )

  invisible()
}
