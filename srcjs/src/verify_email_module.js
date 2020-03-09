
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

      firebase.auth().currentUser.reload()
      .then(ok => {

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



