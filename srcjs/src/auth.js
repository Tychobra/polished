const db = firebase.firestore()
const functions = firebase.functions()
const isUserInvited = functions.httpsCallable("isUserInvited")

const sign_in = (email, password) => {
  return auth.signInWithEmailAndPassword(email, password).catch(error => {
    toastr.error("Sign in Error: " + error.message)
    $.LoadingOverlay("hide")
    console.log('sign in error: ', error)
  })
}

const does_email_exist = (email) => {
  return db.collection("apps")
  .doc(app_name)
  .collection("users")
  .doc(email).get().then(doc => {
    if (doc.exists) {
      return true
    } else {
      return false
    }
  }).catch(error => {
    console.log("error checking if email exists")
    console.log(error)
    toastr.error("Error checking email")
  })
}


$(document).on('click', '#submit_continue_sign_in', () => {
  $.LoadingOverlay("show", {
    fade: false,
    background: "rgba(255, 255, 255, 0.5)",
    text: "Checking Invite..."
  })

  const email = $('#email').val().toLowerCase()

  isUserInvited({ email: email, app_name: app_name }).then(result => {
    const is_invited = result.data.is_invited

    if (is_invited === true) {

      // the user has been invited so allow the user to set their password and register
      $("#continue_sign_in").hide()
      $("#sign_in_password").slideDown()
    } else {
      toastr.error("You must have an invite to access this app")
    }

    return null

  }).then(() => {
    $.LoadingOverlay("hide")
  }).catch(error => {
    $.LoadingOverlay("hide")
    toastr.error("" + error)
    console.log("error checking app 'users'")
    console.log(error)
  })

})

$(document).on('click', '#submit_sign_in', () => {
  $.LoadingOverlay("show", loading_options)

  const email = $('#email').val().toLowerCase()
  const password = $('#password').val()


  // check that user has an invite
  isUserInvited({ email: email, app_name: app_name }).then(result => {
    const is_invited = result.data.is_invited

    if (is_invited === true) {
      sign_in(email, password)
    } else {
      toastr.error("You must have an invite to access this app")
    }

  }).catch(error => {
    console.log(error)
    toastr.error("" + error)
  })
})


$(document).on("click", "#submit_register", () => {
  const email = $("#register_email").val().toLowerCase()
  const password = $("#register_password").val()
  const password_2 = $("#register_password_verify").val()

  if (password !== password_2) {

    toastr.error("The passwords do not match")

    return
  }

  $.LoadingOverlay("show", loading_options)
  // double check that the email is in "invites" collection


  isUserInvited({ email: email, app_name: app_name }).then(result => {
    const is_invited = result.data.is_invited
    if (is_invited === true) {
      return auth.createUserWithEmailAndPassword(email, password).then((userCredential) => {

        // set authorization for this user for this Shiny app
        db.collection("apps")
        .doc(app_name)
        .collection("users")
        .doc(email)
        .set({
          invite_status: "accepted"
        }, { merge: true })



        return userCredential

      }).then((userCredential) => {

        // send verification email
        return userCredential.user.sendEmailVerification().catch(error => {
          console.error("Error sending email verification", error)
        })

      })

    } else {

      throw "You must have an invite to access this app"
    }


  }).then((obj) => {
    $.LoadingOverlay("hide")
  }).catch((error) => {
    toastr.error("" + error)
    $.LoadingOverlay("hide")
    console.log("error registering user")
    console.log(error)
  })

})


$(document).on("click", "#reset_password", () => {
  const email = $("#email").val().toLowerCase()

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

  const email = $("#register_email").val().toLowerCase()

  $.LoadingOverlay("show", {
    fade: false,
    background: "rgba(255, 255, 255, 0.5)",
    text: "Checking Invite..."
  })

  // `isUserInvited` will return `true` if the user is invited or `false` otherwise
  isUserInvited({ email: email, app_name: app_name }).then(result => {

    if (result.data.is_invited === true) {

      // the user has been invited so allow the user to set their password and register
      $("#continue_registation").hide()
      $("#register_passwords").slideDown()
    } else {
      toastr.error("You must have an invite to access this app")
    }

    return null

  }).then(() => {
    $.LoadingOverlay("hide")
  }).catch(error => {
    $.LoadingOverlay("hide")
    toastr.error("" + error)
    console.log("error checking app 'users'")
    console.log(error)
  })

})
