var auth = firebase.auth()

$(document).on("click", "#resend_verification_email", () => {

  const user = auth.currentUser

  user.sendEmailVerification()
  .then(() => {
    // TODO: add toast
  })
  .catch((error) => {
    // TODO: toast
    console.error('error sending email verification', error)
  })
})
