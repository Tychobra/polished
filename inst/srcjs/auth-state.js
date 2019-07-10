



auth.onAuthStateChanged(firebase_user => {

  if (firebase_user === null) {
    Shiny.setInputValue('polish__sign_out', null)
    Shiny.setInputValue('polish__token', null, { priority: 'event' })
  } else {

    $.LoadingOverlay("show", loading_options)
    auth.currentUser.getIdToken(/* forceRefresh true*/).then(function(idToken) {
      console.log("getIdToken: ", idToken)
      Shiny.setInputValue('polish__token', idToken, { priority: 'event' })
    }).catch(function(error) {
       console.log('error getting token')
       console.log(error)
    })

  }

})
