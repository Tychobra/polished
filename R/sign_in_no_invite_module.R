#' Generates sign in page that does not require user invites
#'
#' UI for the sign in and registration pages. \code{sign_in_no_invite_module} does not
#' require your users to be invited to your 'shiny' app before registering and signing
#' in.  i.e. if you use \code{sign_in_no_invite_module}, anyone will be able to register
#' and sign in to access your 'shiny' app.  See \code{\link{sign_in_module}} if you wish
#' to limit access to only invited users.
#'
#' @inheritParams sign_in_module_ui
#'
#' @importFrom shiny NS actionLink
#' @importFrom htmltools tagList tags div h1 br hr
#' @importFrom shinyjs useShinyjs hidden
#' @importFrom shinyFeedback loadingButton useShinyFeedback
#'
#' @export
#'
#'
sign_in_no_invite_module_ui <- function(id) {
  ns <- shiny::NS(id)

  providers <- .global_sessions$sign_in_providers

  email_ui <- tags$div(
    id = ns("email_ui"),
    tags$div(
      id = ns("sign_in_panel_top"),
      htmltools::h1(
        class = "text-center",
        style = "padding-top: 0;",
        "Sign In"
      )
    ),
    shinyjs::hidden(tags$div(
      id = ns("register_panel_top"),
      tags$h1(
        class = "text-center",
        style = "padding-top: 0;",
        "Register"
      )
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
        shinyFeedback::loadingButton(
          ns("submit_sign_in"),
          label = "Sign In",
          class = "btn btn-primary btn-lg text-center",
          style = "width: 100%",
          loadingLabel = "Authenticating...",
          loadingClass = "btn btn-primary btn-lg text-center",
          loadingStyle = "width: 100%"
        )
      ),
      tags$div(
        style = "text-align: center;",
        tags$hr(),
        shiny::actionLink(
          inputId = ns("go_to_register"),
          label = "Not a member? Register!"
        ),
        tags$br(),
        tags$button(
          class = 'btn btn-link btn-small',
          id = ns("reset_password"),
          "Forgot your password?"
        )
      )
    ),



    shinyjs::hidden(div(
      id = ns("register_panel_bottom"),

      tags$div(
        id = ns("register_passwords"),
        tags$div(
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
        tags$br(),
        tags$div(
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
        tags$br(),
        tags$div(
          style = "text-align: center;",
          shinyFeedback::loadingButton(
            ns("submit_register"),
            label = "Register",
            class = "btn btn-primary btn-lg",
            style = "width: 100%",
            loadingLabel = "Registering...",
            loadingClass = "btn btn-primary btn-lg text-center",
            loadingStyle = "width: 100%"
          )
        )
      ),
      tags$div(
        style = "text-align: center",
        tags$hr(),
        shiny::actionLink(
          inputId = ns("go_to_sign_in"),
          label = "Already a member? Sign in!"
        ),
        tags$br()
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
  fluidPage(
    fluidRow(
      shinyjs::useShinyjs(),
      tags$div(
        class = "auth_panel",
        ui_out
      )
    ),

    sign_in_js(ns)
  )
}

#' sign_in_no_invite_module
#'
#' @param input the Shiny input
#' @param output the Shiny output
#' @param session the Shiny session
#'
#' @importFrom shiny observeEvent getQueryString observe
#' @importFrom shinyjs show hide
#' @importFrom digest digest
#'
sign_in_no_invite_module <- function(input, output, session) {
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
  shiny::observe({
    query_string <- shiny::getQueryString()

    if (identical(query_string$register, "TRUE")) {
      go_to_registration_page()
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

  sign_in_check_jwt(
    jwt = shiny::reactive({input$check_jwt})
  )

  invisible()
}
