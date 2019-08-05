"use strict";

var auth = firebase.auth();
$(document).on("shiny:sessioninitialized", function () {
  auth.onAuthStateChanged(function (firebase_user) {
    if (firebase_user === null) {
      // sign out
      Shiny.setInputValue('polish__sign_out', 1, {
        priority: 'event'
      });
    } else {
      firebase_user.getIdToken(
      /*forceRefresh*/
      true).then(function (idToken) {
        Cookies.set('polish__uid', firebase_user.uid);
        var session = Cookies.get('polish__session');

        if (typeof session === "undefined") {
          session = "p_" + Math.random();
          Cookies.set('polish__session', session);
        }

        Shiny.setInputValue('polish__sign_in', {
          token: idToken,
          uid: firebase_user.uid,
          session: session
        }, {
          priority: 'event'
        });
      })["catch"](function (error) {
        console.log('error getting token');
        console.log(error);
      }); //var current_user = auth.currentUser
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
  });
  Shiny.addCustomMessageHandler("polish__sign_out", function (message) {
    Cookies.remove('polish__uid');
    Cookies.remove('polish__session');
    auth.signOut()["catch"](function (error) {
      console.error("sign out error: ", error);
    });
  });
});