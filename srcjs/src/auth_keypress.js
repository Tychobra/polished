





const auth_keypress = (ns_prefix) => {


  $(`#${ns_prefix}sign_in_email`).on("keypress", e => {

    if(e.which == 13) {


      if ($(`#${ns_prefix}submit_continue_sign_in`).is(":visible")) {

        $(`#${ns_prefix}submit_continue_sign_in`).click()

      } else {

        $(`#${ns_prefix}sign_in_submit`).click()

      }
    }
  })

  $(`#${ns_prefix}register_email`).on("keypress", e => {

    if(e.which == 13) {
      if ($(`#${ns_prefix}submit_continue_register`).is(":visible")) {

        $(`#${ns_prefix}submit_continue_register`).click()

      } else {


        $(`#${ns_prefix}register_submit`).click()

      }
    }
  })


  $(`#${ns_prefix}sign_in_password`).on('keypress', e => {
    if(e.which == 13) {
      $(`#${ns_prefix}sign_in_submit`).click()
    }
  })


  $(`#${ns_prefix}register_password`).on('keypress', e => {
    if(e.which == 13) {
      $(`#${ns_prefix}register_submit`).click()
    }
  })

  $(`#${ns_prefix}register_password_verify`).on('keypress', e => {
    if(e.which == 13) {
      $(`#${ns_prefix}register_submit`).click()
    }
  })


}




