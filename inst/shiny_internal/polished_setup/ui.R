
ui <- fluidPage(
  tags$head(
    tags$link(href = "styles.css", rel="stylesheet")
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
      id = "sign_in_password",
      div(
        class = "form-group",
        style = "width: 100%;",
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
      tags$button(
        id = "submit_sign_in",
        class = "text-center",
        style = "color: white; width: 100%;",
        type = "button",
        class = "btn btn-primary btn-lg",
        "Sign In"
      )
    ),
    div(
      style = "text-align: center;",
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
      id = "register_passwords",
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
        class = "form-group",
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


  # TODO: switch this over to Shiny dashboard
  div(
    id = "signed_in_ui",
    style = "display: none;",
    class = "auth_panel",
    h1("Add User"),
    div(
      class = "form-group",
      style = "width: 100%",
      tags$label(
        tagList("email"),
        `for` = "first_user_email"
      ),
      tags$input(
        id = "first_user_email",
        type = "text",
        class = "form-control",
        value = ""
      )
    ),
    div(
      class = "form-group",
      style = "width: 100%",
      tags$label(
        tagList("App Name"),
        `for` = "first_user_app_name"
      ),
      tags$input(
        id = "first_user_app_name",
        type = "text",
        class = "form-control",
        value = ""
      )
    ),
    br(),
    br(),
    div(
      style = "text-align: center;",
      tags$button(
        id = "submit_add_first_user",
        style = "color: white; width: 100%;",
        type = "button",
        class = "btn btn-primary btn-lg",
        "Add User"
      )
    )
  )

)



ui_w_firebase(
  ui,
  app_config$firebase,
  app_config$firebase_functions_url
)
