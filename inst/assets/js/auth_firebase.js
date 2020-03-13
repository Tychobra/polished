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
    var email = $("#".concat(ns_prefix, "register_email")).val().toLowerCase();
    var password = $("#".concat(ns_prefix, "register_password")).val();
    var password_2 = $("#".concat(ns_prefix, "register_password_verify")).val();

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
  $(document).on("click", "#".concat(ns_prefix, "reset_password"), function () {
    var email = $("#".concat(ns_prefix, "email")).val().toLowerCase();
    auth.sendPasswordResetEmail(email).then(function () {
      console.log("Password reset email sent to ".concat(email));
      toastr.success("Password reset email sent to " + email, null, toast_options);
    })["catch"](function (error) {
      toastr.error("" + error, null, toast_options);
      console.log("error resetting email: ", error);
    });
  });
  $(document).on("click", "#".concat(ns_prefix, "submit_sign_in"), function () {
    $.LoadingOverlay("show", loading_options);
    var email = $("#".concat(ns_prefix, "email")).val().toLowerCase();
    var password = $("#".concat(ns_prefix, "password")).val();
    sign_in(email, password)["catch"](function (error) {
      $.LoadingOverlay("hide");
      toastr.error("Sign in Error: " + error.message, null, toast_options);
      console.log("error: ", error);
    });
  });
};