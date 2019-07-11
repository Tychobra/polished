// js that needs to be loaded on all tychobraauth views
var auth = firebase.auth()

auth.onAuthStateChanged(firebase_user => {

  if (firebase_user === null) {
    Shiny.setInputValue('polish__token', null, { priority: 'event' })
  } else {

    //$.LoadingOverlay("show", loading_options)
    auth.currentUser.getIdToken(/* forceRefresh true*/).then(function(idToken) {
      console.log("getIdToken: ", idToken)

      Cookies.set('polish__token', idToken)

      Shiny.setInputValue('polish__token', idToken, { priority: 'event' })
    }).catch(function(error) {
       console.log('error getting token')
       console.log(error)
    })

  }

})

Shiny.addCustomMessageHandler(
  "polish__sign_out",
  function(message) {

    Cookies.remove('polish__token');

    auth.signOut().catch(error => {
      console.error("sign out error: ", error)
    })
  }
)

