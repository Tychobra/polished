const auth = firebase.auth()

const sign_in = (email, password) => {

  return auth.signInWithEmailAndPassword(email, password).then(user => {

    const polished_token = Cookies.get("polished__token")

    return user.user.getIdToken(true).then(firebase_token => {

      Shiny.setInputValue("polished__sign_in", {
        firebase_token: firebase_token,
        polished_token: polished_token
      }, {
        event: "priority"
      });
    })


  })
}


const auth_firebase = (ns_id) => {
  const ns = NS(ns_id)


  $(document).on("click", ns("submit_register"), () => {
    const email = $(ns("register_email")).val().toLowerCase()
    const password = $(ns("register_password")).val()
    const password_2 = $(ns("register_password_verify")).val()

    if (password !== password_2) {

      //toastr.error("The passwords do not match")
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
        toastr.error("Sign in Error: " + error.message)
        console.log("error: ", error)
      })

    }).catch((error) => {
      //toastr.error("" + error)
      $.LoadingOverlay("hide")
      console.log("error registering user")
      console.log(error)
    })

  })


  $(document).on("click", ns("reset_password"), () => {
    const email = $(ns("email")).val().toLowerCase()

    auth.sendPasswordResetEmail(email).then(() => {
      console.log(`Password reset email sent to ${email}`)
      //toastr.success("Password reset email sent to " + email)
    }).catch((error) => {
      //toastr.error("" + error)
      console.log("error resetting email: ", error)
    })
  })

  $(document).on("click", ns("submit_sign_in"), () => {
    $.LoadingOverlay("show", loading_options)

    const email = $(ns("email")).val().toLowerCase()
    const password = $(ns("password")).val()

    sign_in(email, password).catch(error => {

      $.LoadingOverlay("hide")
      toastr.error("Sign in Error: " + error.message)
      console.log("error: ", error)
    })

  })

}


