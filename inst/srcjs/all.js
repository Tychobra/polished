// js that needs to be loaded on all tychobraauth views
var auth = firebase.auth()


var loading_options = {
  //background: "rgba(0, 0, 0, 0.8)",
  text: "Authenticating..."
}



Shiny.addCustomMessageHandler(
  "remove_loading",
  function(message) {
    $.LoadingOverlay("hide")
  }
)

Shiny.addCustomMessageHandler(
  "polish__sign_out",
  function(message) {
    console.log("sign out ran")
    auth.signOut().catch(error => {
      console.error("sign out error: ", error)
    })
  }
)
