





const auth_keypress = (ns_prefix) => {


  $(`#${ns_prefix}email`).on("keypress", e => {

    if(e.which == 13) {

      if ($(`#${ns_prefix}sign_in_panel_top`).is(":visible")) {
        // user is on sign in page
        if ($(`#${ns_prefix}submit_continue_sign_in`).is(":visible")) {

          $(`#${ns_prefix}submit_continue_sign_in`).click()

        } else {

          $(`#${ns_prefix}submit_sign_in`).click()

        }
      } else {
        // user is on register page

        if ($(`#${ns_prefix}submit_continue_register`).is(":visible")) {

          $(`#${ns_prefix}submit_continue_register`).click()

        } else {


          $(`#${ns_prefix}submit_register`).click()

        }

      }

    }
  })

  $(`#${ns_prefix}password`).on('keypress', e => {
    if(e.which == 13) {
      $(`#${ns_prefix}submit_sign_in`).click()
    }
  })


  $(`#${ns_prefix}register_password`).on('keypress', e => {
    if(e.which == 13) {
      $(`#${ns_prefix}submit_register`).click()
    }
  })

  $(`#${ns_prefix}register_password_verify`).on('keypress', e => {
    if(e.which == 13) {
      $(`#${ns_prefix}submit_register`).click()
    }
  })


}




