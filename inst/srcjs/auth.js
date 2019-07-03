var db = firebase.firestore()


const sign_in = function(email, password) {
  return auth.signInWithEmailAndPassword(email, password).then(function(user) {
    console.log("user", user)
    // send firebase token to shiny server.R
    auth.currentUser.getIdToken(/* forceRefresh */ true).then(function(idToken) {
      Shiny.setInputValue('polish__token', idToken)
    }).catch(function(error) {
       console.log('error getting token')
    })

  }).catch(function(error) {
    toastr.error("Sign in Error: " + error.message)
    $.LoadingOverlay("hide")
    console.log('sign in error: ', error)
  })
}

$(document).on('click', '#submit_sign_in', function() {
  $.LoadingOverlay("show", loading_options)

  var email = $('#email').val()
  var password = $('#password').val()

  sign_in(email, password)

})


$(document).on("click", "#submit_register", () => {
  const email = $("#register_email").val()
  const password = $("#register_password").val()
  const password_2 = $("#register_password_verify").val()

  console.log("password: ", password)
  console.log("password_2: ", password_2)

  if (password !== password_2) {

    toastr.error("The passwords do not match")

    return
  }

  // double check that the email is in "invites" collection
  db.collection("apps")
  .doc(app_name)
  .collection("users")
  .doc(email).get().then((doc) => {

    if (doc.exists) {
      return auth.createUserWithEmailAndPassword(email, password).then((user) => {

        // set authorization for this user for this Shiny app
        //const registerSetup = functions.httpsCallable("registerSetup")

        db.collection("apps")
        .doc(app_name)
        .collection("users")
        .doc("email")
        .set({
          invite_status: "accepted"
        }, { merge: true })
        .catch(error => {
          console.log("error setting invite status on register")
        })
        //registerSetup()

        return user

      }).then((user) => {

        sign_in(email, password)

        return null
      })

    } else {

      swal({
        title: "Not Authorized",
        text: "You must have an invite to access this app.  Please contact the app owner to get an invite.",
        icon: "error"
      })

      return null
    }


  }).then(user => {

    if (user !== null) {
      user.user.sendEmailVerification().catch((error) => {
        //showSnackbar("register_snackbar", "Error: " + error.message)
        console.error("error sending email verification: ", error)
      })
    }

  }).catch((error) => {
    toastr.error("" + error)
    console.log("error registering user")
    console.log(error)
  })

})


$(document).on("click", "#reset_password", () => {
  const email = $("#email").val()

  auth.sendPasswordResetEmail(email).then(() => {
    toastr.success("Password reset email sent to " + email)
  }).catch((error) => {
    toastr.error("" + error)
    console.log("error resetting email: ", error)
  })
})


// navigate between sign in and register pages
$(document).on("click", "#go_to_register", () => {

  $("#sign_in_panel").hide()
  $("#register_panel").show()

})

$(document).on("click", "#go_to_sign_in", () => {

  $("#register_panel").hide()
  $("#sign_in_panel").show()

})


$(document).on("click", "#submit_continue_register", () => {

  const email = $("#register_email").val()
  console.log("register email", email)
  db.collection("apps")
  .doc(app_name)
  .collection("users")
  .doc(email).get().then((doc) => {
    console.log("check user invited")
    if (doc.exists) {

      // TODO: could check invite or registration status here to see if the user is already
      // registered.  probably not worth it at the moment since it may get out of sync with actual
      // firebase auth registered users

      console.log("i ran too")
      // the user has been invited so allow the user to set their password and register
      $("#continue_registation").hide()
      $("#register_passwords").slideDown()



    } else {
      swal({
        title: "Not Authorized",
        text: "You must have an invite to access this app.  Please contact the app owner to get an invite.",
        icon: "error"
      })
    }

  }).catch(error => {
    console.log("error checking app 'users'")
    console.log(error)
  })
})
