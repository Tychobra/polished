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
      });
    }
  });
  Shiny.addCustomMessageHandler("polish__sign_out", function (message) {
    Cookies.remove('polish__uid');
    Cookies.remove('polish__session');
    auth.signOut().then(function () {
      Shiny.setInputValue("polish__reload", 1, {
        priority: 'event'
      });
    })["catch"](function (error) {
      Shiny.setInputValue("polish__reload", 1, {
        priority: 'event'
      });
      console.error("sign out error: ", error);
    });
  });
});