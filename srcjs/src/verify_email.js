
function verify_email(ns_prefix) {

  $(function() {

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


    this.checkForVerifiedInterval = setInterval(() => {

      firebase.auth().currentUser.reload()
      .then(ok => {

        if (auth.currentUser.emailVerified) {

          auth.currentUser.getIdToken(true).then(firebase_token => {

            Shiny.setInputValue(`${ns_prefix}refresh_email_verification`,
              firebase_token,
              { event: "priority" }
            )

          })

          clearInterval(this.checkForVerifiedInterval)
        }

      })
    }, 1000)


  })
}



