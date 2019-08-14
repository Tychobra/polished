
$(document).on("click", "#go_to_register", function(event) {
  event.preventDefault()
  $("#sign_in_panel").hide()
  $("#register_panel").show()
  $("#signed_in_ui").hide()
})

$(document).on("click", "#go_to_sign_in", function(event) {
  event.preventDefault()
  $("#register_panel").hide()
  $("#sign_in_panel").show()
  $("#signed_in_ui").hide()
})

var auth = firebase.auth()
var functions = firebase.functions()
var addFirstUser = functions.httpsCallable("addFirstUser")


$(document).on("click", "#submit_sign_in", function() {

  var email = $("#email").val()
  var password = $("#password").val()

  auth.signInWithEmailAndPassword(email, password).catch(function(error) {
    toastr.error("Sign in Error: " + error.message)
    console.log('sign in error: ', error)
  })
})

$(document).on("click", "#submit_register", function() {

  var email = $("#email_register").val()
  var password = $("#password_register").val()
  var password_2 = $("#password_verify").val()

  //console.log("email: ", email)
  //console.log("password: ", password)
  //console.log("password_2: ", password_2)



})

auth.onAuthStateChanged(function(firebase_user) {


  if (firebase_user === null) {
    // sign out
    //Shiny.setInputValue("polish__user", null, { priority: "event" })
    $("#register_panel").hide()
    $("#sign_in_panel").show()
    $("#signed_in_ui").hide()
  } else {
    $("#register_panel").hide()
    $("#sign_in_panel").hide()
    $("#signed_in_ui").show()
    //Shiny.setInputValue("polish__user", firebase_user, { priority: "event" })


  }
})

$(document).on("click", "#sign_out", function(event) {
  event.preventDefault()

  auth.signOut().catch(function(error) {
    toastr.error("Sign Out Error: " + error.message)
    console.log("Sign Out Error: " + error)
  })
})


$(document).on("click", "#submit_add_first_user", function(event) {
  console.log("I ran")
  var email = $("#first_user_email").val()
  var app_name = $("#first_user_app_name").val()

  addFirstUser({ email: email, app_name: app_name}).then(function(result) {
    console.log("first user successfully created")
    console.log(result)
  }).catch(function(error) {
    console.log("error creating first user: ", error)
  })

})

