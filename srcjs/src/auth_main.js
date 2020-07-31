
const auth_main = (ns_prefix) => {

  const sign_in = (email, password) => {

    const polished_cookie = "p" + Math.random()

    Cookies.set(
      'polished',
      polished_cookie,
      { expires: 365 } // set cookie to expire in 1 year
    )

    Shiny.setInputValue(`${ns_prefix}check_jwt`, {
      email: email,
      password: password,
      cookie: polished_cookie
    }, {
      event: "priority"
    });
  }

  $(document).on("click", `#${ns_prefix}register_submit`, () => {
    const email = $(`#${ns_prefix}register_email`).val().toLowerCase()
    const password = $(`#${ns_prefix}register_password`).val()
    const password_2 = $(`#${ns_prefix}register_password_verify`).val()

    if (password !== password_2) {
      // Event to reset Register loading button from loading state back to ready state
      loadingButtons.resetLoading(`${ns_prefix}register_submit`);

      toastr.error("The passwords do not match", null, toast_options)
      console.log("the passwords do not match")

      return
    }



    const polished_cookie = "p" + Math.random()

    Cookies.set(
      'polished',
      polished_cookie,
      { expires: 365 } // set cookie to expire in 1 year
    )

    Shiny.setInputValue(`${ns_prefix}register_js`, {
      email: email,
      password: password,
      cookie: polished_cookie
    }, {
      event: "priority"
    });

  })




  $(document).on("click", `#${ns_prefix}sign_in_submit`, () => {

    const email = $(`#${ns_prefix}sign_in_email`).val().toLowerCase()
    const password = $(`#${ns_prefix}sign_in_password`).val()

    sign_in(email, password)

  })

}

