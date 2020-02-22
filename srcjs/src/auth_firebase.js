const auth = firebase.auth()




const auth_firebase = (ns_prefix) => {


  const sign_in = (email, password) => {

    return auth.signInWithEmailAndPassword(email, password).then(user => {



      return user.user.getIdToken(true).then(firebase_token => {

        const polished_token = "p" + Math.random()


        Cookies.set(
          'polished__token',
          polished_token,
          { expires: 365 } // set cookie to expire in 1 year
        )

        Shiny.setInputValue(`${ns_prefix}check_jwt`, {
          jwt: firebase_token,
          polished_token: polished_token
        }, {
          event: "priority"
        });
      })


    })
  }

  Shiny.addCustomMessageHandler(
    `${ns_prefix}polished__set_cookie`,
    function(message) {
      Cookies.set('polished__token', message.polished_token)

      Shiny.setInputValue(`${ns_prefix}polished__set_cookie_complete`, 1, { priority: "event" })
    }
  )

  $(document).on("click", `#${ns_prefix}submit_register`, () => {
    const email = $(`#${ns_prefix}register_email`).val().toLowerCase()
    const password = $(`#${ns_prefix}register_password`).val()
    const password_2 = $(`#${ns_prefix}register_password_verify`).val()

    if (password !== password_2) {

      toastr.error("The passwords do not match", null, toast_options)
      console.log("the passwords do not match")

      return
    }

    $.LoadingOverlay("show", loading_options)
    // double check that the email is in "invites" collection



    auth.createUserWithEmailAndPassword(email, password).then((userCredential) => {

      // send verification email
      return userCredential.user.sendEmailVerification().catch(error => {
        console.error("Error sending email verification", error)
      })


    }).then(() => {

      return sign_in(email, password).catch(error => {
        $.LoadingOverlay("hide")
        toastr.error("Sign in Error: " + error.message, null, toast_options)
        console.log("error: ", error)
      })

    }).catch((error) => {
      toastr.error("" + error, null, toast_options)
      $.LoadingOverlay("hide")
      console.log("error registering user")
      console.log(error)
    })

  })


  $(document).on("click", `#${ns_prefix}reset_password`, () => {
    const email = $(`#${ns_prefix}email`).val().toLowerCase()

    auth.sendPasswordResetEmail(email).then(() => {
      console.log(`Password reset email sent to ${email}`)
      toastr.success("Password reset email sent to " + email, null, toast_options)
    }).catch((error) => {
      toastr.error("" + error, null, toast_options)
      console.log("error resetting email: ", error)
    })
  })

  $(document).on("click", `#${ns_prefix}submit_sign_in`, () => {
    $.LoadingOverlay("show", loading_options)

    const email = $(`#${ns_prefix}email`).val().toLowerCase()
    const password = $(`#${ns_prefix}password`).val()

    sign_in(email, password).catch(error => {

      $.LoadingOverlay("hide")
      toastr.error("Sign in Error: " + error.message, null, toast_options)
      console.log("error: ", error)
    })

  })

}


