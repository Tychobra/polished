



auth.onAuthStateChanged(firebase_user => {

  if (firebase_user === null) {
    Shiny.setInputValue('polish__sign_out', null)
  } else {

    $.LoadingOverlay("show", loading_options)
    auth.currentUser.getIdToken(/* forceRefresh true*/).then(function(idToken) {
      console.log("idToken: ", idToken)
      Shiny.setInputValue('polish__token', idToken)
    }).catch(function(error) {
       console.log('error getting token')
    })

  }

})
