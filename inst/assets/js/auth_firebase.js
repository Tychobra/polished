"use strict";

var auth = firebase.auth();

var auth_firebase = function auth_firebase(ns_prefix) {
  var sign_in = function sign_in(email, password) {
    return auth.signInWithEmailAndPassword(email, password).then(function (user) {
      return user.user.getIdToken(true).then(function (firebase_token) {
        var polished_cookie = "p" + Math.random();
        Cookies.set('polished', polished_cookie, {
          expires: 365
        } // set cookie to expire in 1 year
        );
        Shiny.setInputValue("".concat(ns_prefix, "check_jwt"), {
          jwt: firebase_token,
          cookie: polished_cookie
        }, {
          event: "priority"
        });
      });
    });
  };

  $(document).on("click", "#".concat(ns_prefix, "submit_register"), function () {
    var email = $("#".concat(ns_prefix, "email")).val().toLowerCase();
    var password = $("#".concat(ns_prefix, "register_password")).val();
    var password_2 = $("#".concat(ns_prefix, "register_password_verify")).val();

    if (password !== password_2) {
      // Event to reset Register loading button from loading state back to ready state
      loadingButtons.resetLoading("".concat(ns_prefix, "submit_register"));
      toastr.error("The passwords do not match", null, toast_options);
      console.log("the passwords do not match");
      return;
    }

    auth.createUserWithEmailAndPassword(email, password).then(function (userCredential) {
      // send verification email
      return userCredential.user.sendEmailVerification()["catch"](function (error) {
        console.error("Error sending email verification", error);
        loadingButtons.resetLoading("".concat(ns_prefix, "submit_register"));
      });
    }).then(function () {
      return sign_in(email, password)["catch"](function (error) {
        toastr.error("Sign in Error: ".concat(error.message), null, toast_options);
        console.log("error: ", error);
        loadingButtons.resetLoading("".concat(ns_prefix, "submit_sign_in"));
      });
    })["catch"](function (error) {
      toastr.error("" + error, null, toast_options);
      console.log("error registering user");
      console.log(error);
      loadingButtons.resetLoading("".concat(ns_prefix, "submit_register"));
    });
  });
  $(document).on("click", "#".concat(ns_prefix, "reset_password"), function () {
    var email = $("#".concat(ns_prefix, "email")).val().toLowerCase();
    auth.sendPasswordResetEmail(email).then(function () {
      console.log("Password reset email sent to ".concat(email));
      toastr.success("Password reset email sent to ".concat(email), null, toast_options);
    })["catch"](function (error) {
      toastr.error("" + error, null, toast_options);
      console.log("error resetting email: ", error);
    });
  });
  $(document).on("click", "#".concat(ns_prefix, "submit_sign_in"), function () {
    var email = $("#".concat(ns_prefix, "email")).val().toLowerCase();
    var password = $("#".concat(ns_prefix, "password")).val();
    sign_in(email, password)["catch"](function (error) {
      // Event to reset Sign In loading button
      loadingButtons.resetLoading("".concat(ns_prefix, "submit_sign_in"));
      toastr.error("Sign in Error: ".concat(error.message), null, toast_options);
      console.log("error: ", error);
    });
  });
  $(document).on("shiny:sessioninitialized", function () {
    console.log("i ran"); // check if the email address is already register

    Shiny.addCustomMessageHandler("".concat(ns_prefix, "check_registered"), function (message) {
      auth.fetchSignInMethodsForEmail(message.email).then(function (res) {
        debugger;
        var is_registered = false;

        if (res.length > 0) {
          is_registered = true;
        }

        Shiny.setInputValue("".concat(ns_prefix, "check_registered_res"), is_registered, {
          priority: "event"
        });
      })["catch"](function (err) {
        Shiny.setInputValue("".concat(ns_prefix, "check_registered_res"), err, {
          priority: "event"
        });
        console.log("error: ", err);
      });
    });
  });
};