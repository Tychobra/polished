

$(document).on("click", "#resend_verification_email", () => {

  const user = auth.currentUser

  user.sendEmailVerification().then(() => {

    toastr.success("Error sending email verification")


  }).catch((error) => {

    toastr.error("Error sending email verification")
    console.error("Error sending email verification", error)
  })
})
