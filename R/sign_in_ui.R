#' sign_in_ui
#'
#' @param firebase_config list of Firebase config
#'
#' @export
#'
#'
sign_in_ui <- function(firebase_config) {
  tagList(
    tags$head(
      tags$link(rel = "shortcut icon", href = "polish/images/tychobra-icon-blue.png"),
      # load toastr assets
      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.js"),
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.css"),
      # sweetalert assets
      tags$script(src="https://unpkg.com/sweetalert/dist/sweetalert.min.js")
    ),
    div(
      id = "sign_in_panel",
      class = "auth_panel",
      h1(
        class = "text-center",
        style = "padding-top: 0;",
        "Sign In"
      ),
      br(),
      div(
        class = "form-group",
        style = "width: 100%",
        tags$label(
          tagList(icon("envelope"), "email"),
          `for` = "email"
        ),
        tags$input(
          id = "email",
          type = "text",
          class = "form-control",
          value = ""
        )
      ),
      br(),
      div(
        class = "form-group",
        style = "width: 100%",
        tags$label(
          tagList(icon("unlock-alt"), "password"),
          `for` = "password"
        ),
        tags$input(
          id = "password",
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
        tags$button(
          id = "submit_sign_in",
          style = "color: white; width: 100%;",
          type = "button",
          class = "btn btn-primary btn-lg",
          "Sign In"
        ),
        br(),
        hr(),
        br(),
        tags$a(
          id = "go_to_register",
          href = "#",
          "Not a member? Register!"
        ),
        br(),
        br(),
        tags$a(
          id = "reset_password",
          href = "#",
          "Forgot your password?"
        )
      )
    ),



    div(
      id = "register_panel",
      style = "display: none;",
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
        tags$label(
          tagList(icon("envelope"), "email"),
          `for` = "register_email"
        ),
        tags$input(
          id = "register_email",
          type = "text",
          class = "form-control",
          value = ""
        )
      ),
      div(
        id = "continue_registation",
        br(),
        tags$button(
          id = "submit_continue_register",
          style = "color: white; width: 100%;",
          type = "button",
          class = "btn btn-primary btn-lg",
          "Continue"
        )
      ),
      div(
        id = "register_passwords",
        style = "display: none",
        br(),
        div(
          class = "form-group",
          style = "width: 100%",
          tags$label(
            tagList(icon("unlock-alt"), "password"),
            `for` = "register_password"
          ),
          tags$input(
            id = "register_password",
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
            tagList(icon("unlock-alt"), "verify password"),
            `for` = "register_password_verify"
          ),
          tags$input(
            id = "register_password_verify",
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
          tags$button(
            id = "submit_register",
            style = "color: white; width: 100%;",
            type = "button",
            class = "btn btn-primary btn-lg",
            "Register"
          )
        )
      ),
      div(
        style = "text-align: center",
        hr(),
        br(),
        tags$a(
          id = "go_to_sign_in",
          href = "#",
          "Already a member? Sign in!"
        ),
        br(),
        br()
      )
    ),

    tags$script(src = "https://cdn.jsdelivr.net/npm/gasparesganga-jquery-loading-overlay@2.1.6/dist/loadingoverlay.min.js"),
    firebase_dependencies(),
    firebase_init(firebase_config),
    tags$script(src = "polish/js/all.js"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/js-cookie@2/src/js.cookie.min.js"),
    tags$script(src = "polish/js/auth-state.js"),
    tags$script(src = "polish/js/auth.js")
  )
}
