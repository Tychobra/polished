"use strict";

var auth = firebase.auth();

var auth_firebase = function auth_firebase(ns_id) {
  var ns = NS(ns_id);
  var ns_pound = NS(ns_id, "#");

  var sign_in = function sign_in(email, password) {
    return auth.signInWithEmailAndPassword(email, password).then(function (user) {
      return user.user.getIdToken(true).then(function (firebase_token) {
        var polished_token = "p" + Math.random();
        Cookies.set('polished__token', polished_token, // set cookie to expire in 1 year
        {
          expires: 365
        });
        Shiny.setInputValue(ns("check_jwt"), {
          jwt: firebase_token,
          polished_token: polished_token
        }, {
          event: "priority"
        });
      });
    });
  };

  Shiny.addCustomMessageHandler(ns("polished__set_cookie"), function (message) {
    Cookies.set('polished__token', message.polished_token);
    Shiny.setInputValue(ns("polished__set_cookie_complete"), 1, {
      priority: "event"
    });
  });
  $(document).on("click", ns_pound("submit_register"), function () {
    var email = $(ns_pound("register_email")).val().toLowerCase();
    var password = $(ns_pound("register_password")).val();
    var password_2 = $(ns_pound("register_password_verify")).val();

    if (password !== password_2) {
      toastr.error("The passwords do not match", null, toast_options);
      console.log("the passwords do not match");
      return;
    }

    $.LoadingOverlay("show", loading_options); // double check that the email is in "invites" collection

    auth.createUserWithEmailAndPassword(email, password).then(function (userCredential) {
      // send verification email
      return userCredential.user.sendEmailVerification()["catch"](function (error) {
        console.error("Error sending email verification", error);
      });
    }).then(function () {
      return sign_in(email, password)["catch"](function (error) {
        $.LoadingOverlay("hide");
        toastr.error("Sign in Error: " + error.message, null, toast_options);
        console.log("error: ", error);
      });
    })["catch"](function (error) {
      toastr.error("" + error, null, toast_options);
      $.LoadingOverlay("hide");
      console.log("error registering user");
      console.log(error);
    });
  });
  $(document).on("click", ns_pound("reset_password"), function () {
    var email = $(ns_pound("email")).val().toLowerCase();
    auth.sendPasswordResetEmail(email).then(function () {
      console.log("Password reset email sent to ".concat(email));
      toastr.success("Password reset email sent to " + email, null, toast_options);
    })["catch"](function (error) {
      toastr.error("" + error, null, toast_options);
      console.log("error resetting email: ", error);
    });
  });
  $(document).on("click", ns_pound("submit_sign_in"), function () {
    $.LoadingOverlay("show", loading_options);
    var email = $(ns_pound("email")).val().toLowerCase();
    var password = $(ns_pound("password")).val();
    sign_in(email, password)["catch"](function (error) {
      $.LoadingOverlay("hide");
      toastr.error("Sign in Error: " + error.message, null, toast_options);
      console.log("error: ", error);
    });
  });
};