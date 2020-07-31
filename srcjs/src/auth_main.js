const auth = firebase.auth()




const auth_main = (ns_prefix) => {

  const send_token_to_shiny = (user) => {

    return user.getIdToken(true).then(firebase_token => {

      const polished_cookie = "p" + Math.random()


      Cookies.set(
        'polished',
        polished_cookie,
        { expires: 365 } // set cookie to expire in 1 year
      )

      Shiny.setInputValue(`${ns_prefix}check_jwt`, {
        jwt: firebase_token,
        cookie: polished_cookie
      }, {
        event: "priority"
      });
    })
  }


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
    debugger
    sign_in(email, password)

  })


  // Google Sign In
  const provider_google = new firebase.auth.GoogleAuthProvider();

  $(document).on("click", `#${ns_prefix}sign_in_with_google`, () => {
    auth.signInWithPopup(provider_google).then(function(result) {

      return send_token_to_shiny(result.user)
    }).catch(function(err) {

      console.log(err)

      toastr.error(`Sign in Error: ${err.message}`, null, toast_options)
    })
  })

  // Microsoft Sign In
  var provider_microsoft = new firebase.auth.OAuthProvider('microsoft.com');
  $(document).on("click", `#${ns_prefix}sign_in_with_microsoft`, () => {
    auth.signInWithPopup(provider_microsoft).then(function(result) {

      return send_token_to_shiny(result.user)
    }).catch(err => {

      console.log(err)

      toastr.error(`Sign in Error: ${err.message}`, null, toast_options)
    })
  })

  // Facebook Sign In
  var provider_facebook = new firebase.auth.FacebookAuthProvider();
  $(document).on("click", `#${ns_prefix}sign_in_with_facebook`, () => {
    auth.signInWithPopup(provider_facebook).then(function(result) {

      return send_token_to_shiny(result.user)
    }).catch(err => {

      console.log(err)

      toastr.error(`Sign in Error: ${err.message}`, null, toast_options)
    })
  })

}

