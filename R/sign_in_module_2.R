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
sign_in_module_ui_2 <- function(
  id,
  register_link = "First time user? Register here!"
) {
  ns <- shiny::NS(id)
  
  providers <- .global_sessions$sign_in_providers
  
  sign_in_email_ui <- tags$div(
    id = ns("email_ui"),
    tags$br(),
    email_input(
      inputId = ns("sign_in_email"),
      label = tagList(icon("envelope"), "email"),
      value = "",
      width = "100%"
    ),
    tags$br(),
    
    tags$div(
      id = ns("sign_in_panel_bottom"),
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
        shinyFeedback::loadingButton(
          ns("submit_sign_in"),
          label = "Sign In",
          class = "btn btn-primary btn-lg text-center",
          style = "width: 100%",
          loadingLabel = "Authenticating...",
          loadingClass = "btn btn-primary btn-lg text-center",
          loadingStyle = "width: 100%"
        )
      )),
      div(
        id = ns("continue_sign_in"),
        shiny::actionButton(
          inputId = ns("submit_continue_sign_in"),
          label = "Continue",
          width = "100%",
          class = "btn btn-primary btn-lg"
        )
      ),
      div(
        style = "text-align: center;",
        br(),
        tags$button(
          class = 'btn btn-link btn-small',
          id = ns("reset_password"),
          "Forgot your password?"
        )
      )
    )
  )
  
  register_ui <- div(
    h1(
      class = "text-center",
      style = "padding-top: 0;",
      "Register"
    ),
    br(),
    email_input(
      inputId = ns("email"),
      label = tagList(icon("envelope"), "email"),
      value = "",
      width = "100%"
    ),
    br(),
    div(
      id = ns("continue_registation"),
      br(),
      shiny::actionButton(
        inputId = ns("submit_continue_register"),
        label = "Continue",
        width = "100%",
        class = "btn btn-primary btn-lg"
      )
    ),
    shinyjs::hidden(div(
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
          ns("submit_register"),
          label = "Register",
          class = "btn btn-primary btn-lg",
          style = "width: 100%;",
          loadingLabel = "Registering...",
          loadingClass = "btn btn-primary btn-lg text-center",
          loadingStyle = "width: 100%;"
        )
      )
    ))
  )
  
  if (length(providers) == 1 && providers == "email") {
   sign_in_ui <- sign_in_email_ui
      
  } else {
    
    hold_providers_ui <- providers_ui(
      ns,
      providers[providers != "email"],
      title = NULL
    )
    
    sign_in_ui <-  div(
      fluidRow(
        htmltools::h1("Sign In")
      ),
      fluidRow(
        column(
          6,
          sign_in_email_ui
        ),
        column(
          6,
          br(),
          div(
            style = "margin-top: 6px;",
            hold_providers_ui
          )
        )
      )
    )
  }
  
  
  
  htmltools::tagList(
    shinyjs::useShinyjs(),
    tags$div(
      class = "auth_panel_2",
      shiny::tabsetPanel(
        id = ns("tabs"),
        shiny::tabPanel("Sign In", sign_in_ui),
        shiny::tabPanel("Register", register_ui)
      )
    ),
    sign_in_js(ns, include_default_keystrokes = FALSE)
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
#' @importFrom shiny observeEvent observe getQueryString
#' @importFrom shinyjs show hide
#' @importFrom shinyWidgets sendSweetAlert
#' @importFrom digest digest
#'
#'
sign_in_module_2 <- function(input, output, session) {
  ns <- session$ns


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
    hold_email <- tolower(input$sign_in_email)

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
      updateTabsetPanel(
        session,
        "tabs",
        "Register"
      )
      
      updateTextInput(
        session,
        "email",
        value = email
      )

      # open the passwords to continue user registration
      submit_continue_register_rv(submit_continue_register_rv() + 1)
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


  submit_continue_register_rv <- reactiveVal(0)

  observeEvent(input$submit_continue_register, {
    submit_continue_register_rv(submit_continue_register_rv() + 1)
  })

  shiny::observeEvent(submit_continue_register_rv(), {

    email <- tolower(input$email)
    
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
      shinyjs::hide("continue_registation")

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
