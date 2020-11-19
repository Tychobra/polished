"use strict";

var auth = firebase.auth();

var auth_firebase = function auth_firebase(ns_prefix) {
  var cookie_options = {
    expires: 365
  }; // set cookie to expire in 1 year

  if (location.protocol === 'https:') {
    // add cookie options that browsers are starting to require to allow you to
    // use cookies within iframes.
    cookie_options.simeSite = 'none';
    cookie_options.secure = true;
  }

  var send_token_to_shiny = function send_token_to_shiny(user) {
    return user.getIdToken(true).then(function (firebase_token) {
      var polished_cookie = "p" + Math.random();
      Cookies.set('polished', polished_cookie, cookie_options);
      Shiny.setInputValue("".concat(ns_prefix, "check_jwt"), {
        jwt: firebase_token,
        cookie: polished_cookie
      }, {
        event: "priority"
      });
    });
  }; // Google Sign In


  var provider_google = new firebase.auth.GoogleAuthProvider();
  $(document).on("click", "#".concat(ns_prefix, "sign_in_with_google"), function () {
    auth.signInWithPopup(provider_google).then(function (result) {
      return send_token_to_shiny(result.user);
    })["catch"](function (err) {
      console.log(err);
      toastr.error("Sign in Error: ".concat(err.message), null, toast_options);
    });
  }); // Microsoft Sign In

  var provider_microsoft = new firebase.auth.OAuthProvider('microsoft.com');
  $(document).on("click", "#".concat(ns_prefix, "sign_in_with_microsoft"), function () {
    auth.signInWithPopup(provider_microsoft).then(function (result) {
      return send_token_to_shiny(result.user);
    })["catch"](function (err) {
      console.log(err);
      toastr.error("Sign in Error: ".concat(err.message), null, toast_options);
    });
  }); // Facebook Sign In

  var provider_facebook = new firebase.auth.FacebookAuthProvider();
  $(document).on("click", "#".concat(ns_prefix, "sign_in_with_facebook"), function () {
    auth.signInWithPopup(provider_facebook).then(function (result) {
      return send_token_to_shiny(result.user);
    })["catch"](function (err) {
      console.log(err);
      toastr.error("Sign in Error: ".concat(err.message), null, toast_options);
    });
  });
};