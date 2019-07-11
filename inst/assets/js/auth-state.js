// js that needs to be loaded on all tychobraauth views
var auth = firebase.auth()


$(document).on("shiny:sessioninitialized", function() {
  auth.onAuthStateChanged(firebase_user => {

  if (firebase_user === null) {
    //Shiny.setInputValue('polish__token', null, { priority: 'event' })
  } else {

    firebase_user.getIdToken().then(function(idToken) {
      console.log("getIdToken: ", idToken)
      console.log("firebase_user: ", firebase_user)

      Cookies.set('polish__uid', firebase_user.uid)
      Shiny.setInputValue('polish__sign_in', { token: idToken, uid: firebase_user.uid }, { priority: 'event' })

      console.log("getIdToken state: ", idToken)
    }).catch(function(error) {
      console.log('error getting token')
      console.log(error)
    })


    //var current_user = auth.currentUser
    //$.LoadingOverlay("show", loading_options)
    //current_user.getIdToken(/* forceRefresh true*/).then(function(idToken) {
    //  console.log("getIdToken: ", idToken)
//
    //  Cookies.set('polish__token', idToken)
    //  Shiny.setInputValue('polish__token', { token: idToken, uid: auth.c }, { priority: 'event' })
    //}).catch(function(error) {
    //   console.log('error getting token')
    //   console.log(error)
    //})

  }

})


Shiny.addCustomMessageHandler(
  "polish__sign_out",
  function(message) {

    Cookies.remove('polish__uid');

    auth.signOut().catch(error => {
      console.error("sign out error: ", error)
    })
  }
)
})


