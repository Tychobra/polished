const auth = firebase.auth()




const auth_firebase = (ns_prefix) => {


  const sign_in = (email, password) => {

    return auth.signInWithEmailAndPassword(email, password).then(user => {



      return user.user.getIdToken(true).then(firebase_token => {

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


    })
  }

  $(document).on("click", `#${ns_prefix}submit_register`, () => {
    const email = $(`#${ns_prefix}register_email`).val().toLowerCase()
    const password = $(`#${ns_prefix}register_password`).val()
    const password_2 = $(`#${ns_prefix}register_password_verify`).val()

    if (password !== password_2) {
      // Event to reset Register loading button from loading state back to ready state
      $(document).trigger(`tychobratools:reset_loading_button_${ns_prefix}submit_register`)

      toastr.error("The passwords do not match", null, toast_options)
      console.log("the passwords do not match")

      return
    }

    auth.createUserWithEmailAndPassword(email, password).then((userCredential) => {

      // send verification email
      return userCredential.user.sendEmailVerification().catch(error => {
        console.error("Error sending email verification", error)
        $(document).trigger(`tychobratools:reset_loading_button_${ns_prefix}submit_register`)
      })


    }).then(() => {

      return sign_in(email, password).catch(error => {
        toastr.error(`Sign in Error: ${error.message}`, null, toast_options)
        console.log("error: ", error)
        $(document).trigger(`tychobratools:reset_loading_button_${ns_prefix}submit_sign_in`)
      })

    }).catch((error) => {
      toastr.error("" + error, null, toast_options)
      console.log("error registering user")
      console.log(error)
      $(document).trigger(`tychobratools:reset_loading_button_${ns_prefix}submit_register`)
    })

  })


  $(document).on("click", `#${ns_prefix}reset_password`, () => {
    const email = $(`#${ns_prefix}email`).val().toLowerCase()

    auth.sendPasswordResetEmail(email).then(() => {
      console.log(`Password reset email sent to ${email}`)
      toastr.success(`Password reset email sent to ${email}`, null, toast_options)
    }).catch((error) => {
      toastr.error("" + error, null, toast_options)
      console.log("error resetting email: ", error)
    })
  })

  $(document).on("click", `#${ns_prefix}submit_sign_in`, () => {

    const email = $(`#${ns_prefix}email`).val().toLowerCase()
    const password = $(`#${ns_prefix}password`).val()

    sign_in(email, password).catch(error => {

      // Event to reset Sign In loading button
      $(document).trigger(`tychobratools:reset_loading_button_${ns_prefix}submit_sign_in`)
      toastr.error(`Sign in Error: ${error.message}`, null, toast_options)
      console.log("error: ", error)
    })

  })

}


