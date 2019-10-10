const auth = firebase.auth()

$(document).on("click", "#resend_verification_email", () => {

  const user = auth.currentUser
  console.log("current_user: ", user)
  user.sendEmailVerification().then(() => {

    toastr.success("Verification Email Send to " + user.email, null, toast_options)

  }).catch((error) => {

    toastr.error("Error sending email verification", null, toast_options)
    console.error("Error sending email verification", error)
  })
})