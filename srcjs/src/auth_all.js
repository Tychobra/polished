


const NS = (ns_id, prefix = "") => {
  return (input_id) => prefix + ns_id + "-" + input_id
}


const auth_all = (ns_id) => {
  const ns = NS(ns_id)
  const ns_pound = NS(ns_id, "#")


  $(ns_pound("email")).on("keypress", e => {

    if(e.which == 13) {

      if ($(ns_pound("submit_continue_sign_in")).is(":visible")) {

        $(ns_pound("submit_continue_sign_in")).click()

      } else {

        $(ns_pound("submit_sign_in")).click()

      }
    }
  })

  $(ns_pound("password")).on('keypress', e => {
    if(e.which == 13) {
      $(ns_pound("submit_sign_in")).click()
    }
  })

  $(ns_pound("register_email")).on("keypress", e => {

    if(e.which == 13) {

      if ($(ns_pound("submit_continue_register")).is(":visible")) {

        $(ns_pound("submit_continue_register")).click()

      } else {


        $(ns_pound("submit_register")).click()

      }
    }
  })

  $(ns_pound("register_password")).on('keypress', e => {
    if(e.which == 13) {
      $(ns_pound("submit_register")).click()
    }
  })

  $(ns_pound("register_password_verify")).on('keypress', e => {
    if(e.which == 13) {
      $(ns_pound("submit_register")).click()
    }
  })

  Shiny.addCustomMessageHandler(
    ns('remove_loading'),
    function(message) {
      console.log('I ran')
      $.LoadingOverlay("hide")
    }
  )
}




