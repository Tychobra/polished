#' sign_in_module_ui
#'
#' UI for the sign in and register panels
#'
#' @param id the Shiny module id
#' @param register_link default is "First time user? Register here!".  The text that
#' will be used in the link to go to the user registration page.  Set to \code{NULL}
#' if you don't want to use the registration page.
#'
#' @importFrom shiny textInput actionButton NS actionLink
#' @importFrom htmltools tagList tags div h1 br hr
#' @importFrom shinyFeedback useShinyFeedback
#' @importFrom shinyjs useShinyjs hidden
#'
#' @export
#'
#'
sign_in_module_ui <- function(id, register_link = "First time user? Register here!") {
  ns <- shiny::NS(id)

  firebase_config <- .global_sessions$firebase_config


  htmltools::tagList(
    shinyjs::useShinyjs(),
    shinyFeedback::useShinyFeedback(feedback = FALSE),
    tags$div(
      class = "auth_panel",

      tags$div(
        id = ns("sign_in_panel_top"),
        htmltools::h1(
          class = "text-center",
          style = "padding-top: 0;",
          "Sign In"
        ),
      ),

      shinyjs::hidden(div(
        id = ns("register_panel_top"),
        class = "auth_panel",
        h1(
          class = "text-center",
          style = "padding-top: 0;",
          "Register"
        ),
        br(),
      )),


      tags$br(),
      email_input(
        inputId = ns("email"),
        label = tagList(icon("envelope"), "email"),
        value = ""
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
        id = ns("register_panel_bottom"),
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
        )),
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
    ),

    firebase_dependencies(),
    firebase_init(firebase_config),
    tags$script(src = "polish/js/toast_options.js"),
    tags$script(src = "polish/js/auth_all.js"),
    tags$script(paste0("auth_all('", ns(''), "')")),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    tags$script(src = "polish/js/auth_firebase.js?version=6"),
    tags$script(paste0("auth_firebase('", ns(''), "')"))
  )
}

#' sign_in
#'
#' @param input the Shiny input
#' @param output the Shiny output
#' @param session the Shiny session
#'
#' @importFrom shiny observeEvent observe getQueryString
#' @importFrom shinyFeedback showToast resetLoadingButton
#' @importFrom shinyjs show hide
#' @importFrom shinyWidgets sendSweetAlert
#' @importFrom digest digest
#'
sign_in_module <- function(input, output, session) {
  ns <- session$ns

  # if query parameter "register" == TRUE, then go directly to registration page
  observe({
    query_string <- shiny::getQueryString()

    if (identical(query_string$register, "TRUE")) {
      shinyjs::hide("sign_in_panel")
      shinyjs::show("register_panel")
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
      shinyjs::hide("sign_in_panel_top")
      shinyjs::hide("sign_in_panel_bottom")
      shinyjs::show("register_panel_top")
      shinyjs::show("register_panel_bottom")

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


  shiny::observeEvent(input$go_to_register, {
    shinyjs::hide("sign_in_panel_top")
    shinyjs::hide("sign_in_panel_bottom")
    shinyjs::show("register_panel_top")
    shinyjs::show("register_panel_bottom")
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

  observeEvent(input$check_jwt, {
    email <- tolower(input$email)

    tryCatch({

      # user is invited, so attempt sign in
      new_user <- .global_sessions$sign_in(
        input$check_jwt$jwt,
        digest::digest(input$check_jwt$cookie)
      )

      if (is.null(new_user)) {
        shinyFeedback::resetLoadingButton('submit_sign_in')
        # show unable to sign in message
        shinyFeedback::showToast('error', 'sign in error')
        stop('sign_in_module: sign in error', call. = FALSE)

      } else {
        # sign in success
        remove_query_string()
        session$reload()
      }

    }, error = function(e) {
      shinyFeedback::resetLoadingButton('submit_sign_in')
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
