
const loading_text = (text) => {

  return {
    fade: false,
    background: "rgba(255, 255, 255, 1.0)",
    text: text
  }
}

const loading_options = loading_text("Authenticating...")

const NS = (ns_id, prefix = "#") => {
  return (input_id) => prefix + ns_id + "-" + input_id
}


const auth_all = (ns_id) => {
  const ns = NS(ns_id)
  const ns2 = NS(ns_id, "")


  $(ns("email")).on("keypress", e => {

    if(e.which == 13) {

      if ($(ns("submit_continue_sign_in")).is(":visible")) {

        $(ns("submit_continue_sign_in")).click()

      } else {

        $(ns("submit_sign_in")).click()

      }
    }
  })

  $(ns("password")).on('keypress', e => {
    if(e.which == 13) {
      $(ns("submit_sign_in")).click()
    }
  })

  $(ns("register_email")).on("keypress", e => {

    if(e.which == 13) {

      if ($(ns("submit_continue_register")).is(":visible")) {

        $(ns("submit_continue_register")).click()

      } else {


        $(ns("submit_register")).click()

      }
    }
  })

  $(ns("register_password")).on('keypress', e => {
    if(e.which == 13) {
      $(ns("submit_register")).click()
    }
  })

  $(ns("register_password_verify")).on('keypress', e => {
    if(e.which == 13) {
      $(ns("submit_register")).click()
    }
  })


}


Shiny.addCustomMessageHandler(
  "polished__set_cookie",
  function(message) {
    Cookies.set('polished__token', message.polished_token)

    Shiny.setInputValue("polished__set_cookie_complete", 1, { priority: "event" })
  }
)

