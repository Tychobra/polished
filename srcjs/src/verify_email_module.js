
const verify_email_module = (ns_prefix) => {

  $(() => {

    const auth = firebase.auth()

    $(document).on("click", "#resend_verification_email", () => {

      const user = auth.currentUser
      user.sendEmailVerification().then(() => {

      toastr.success("Verification email sent to " + user.email, null, toast_options)




      }).catch((error) => {


        toastr.error("Error: " + error.message, null, toast_options)
        console.error("Error sending email verification", error)
      })
    })




    const check_email_verification = () => {

      // if the current Firebase user was somehow signed out, then sign the user
      // out from Shiny
      if (auth.currentUser === null) {
        Shiny.setInputValue(`${ns_prefix}sign_out`,
          1,
          { event: "priority" }
        )
        return
      }

      auth.currentUser.reload()
      .then(() => {

        if (auth.currentUser.emailVerified) {

          auth.currentUser.getIdToken(true).then(firebase_token => {

            Shiny.setInputValue(`${ns_prefix}refresh_email_verification`,
              firebase_token,
              { event: "priority" }
            )

          })

          clearInterval(check_email_verification_interval)
        }

      })
    }

    const check_email_verification_interval = setInterval(
      check_email_verification,
      1000
    )

  })
}



