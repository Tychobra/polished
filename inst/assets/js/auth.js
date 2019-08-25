"use strict";

var db = firebase.firestore();
var functions = firebase.functions();
var isUserInvited = functions.httpsCallable("isUserInvited");

var sign_in = function sign_in(email, password) {
  return auth.signInWithEmailAndPassword(email, password)["catch"](function (error) {
    toastr.error("Sign in Error: " + error.message);
    $.LoadingOverlay("hide");
    console.log('sign in error: ', error);
  });
};

var does_email_exist = function does_email_exist(email) {
  return db.collection("apps").doc(app_name).collection("users").doc(email).get().then(function (doc) {
    if (doc.exists) {
      return true;
    } else {
      return false;
    }
  })["catch"](function (error) {
    console.log("error checking if email exists");
    console.log(error);
    toastr.error("Error checking email");
  });
};

$(document).on('click', '#submit_continue_sign_in', function () {
  $.LoadingOverlay("show", {
    fade: false,
    background: "rgba(255, 255, 255, 0.5)",
    text: "Checking Invite..."
  });
  var email = $('#email').val().toLowerCase();
  isUserInvited({
    email: email,
    app_name: app_name
  }).then(function (result) {
    var is_invited = result.data.is_invited;

    if (is_invited === true) {
      // the user has been invited so allow the user to set their password and register
      $("#continue_sign_in").hide();
      $("#sign_in_password").slideDown();
    } else {
      toastr.error("You must have an invite to access this app");
    }

    return null;
  }).then(function () {
    $.LoadingOverlay("hide");
  })["catch"](function (error) {
    $.LoadingOverlay("hide");
    toastr.error("" + error);
    console.log("error checking app 'users'");
    console.log(error);
  });
});
$(document).on('click', '#submit_sign_in', function () {
  $.LoadingOverlay("show", loading_options);
  var email = $('#email').val().toLowerCase();
  var password = $('#password').val(); // check that user has an invite

  isUserInvited({
    email: email,
    app_name: app_name
  }).then(function (result) {
    var is_invited = result.data.is_invited;

    if (is_invited === true) {
      sign_in(email, password);
    } else {
      toastr.error("You must have an invite to access this app");
    }
  })["catch"](function (error) {
    console.log(error);
    toastr.error("" + error);
  });
});
$(document).on("click", "#submit_register", function () {
  var email = $("#register_email").val().toLowerCase();
  var password = $("#register_password").val();
  var password_2 = $("#register_password_verify").val();

  if (password !== password_2) {
    toastr.error("The passwords do not match");
    return;
  }

  $.LoadingOverlay("show", loading_options); // double check that the email is in "invites" collection

  isUserInvited({
    email: email,
    app_name: app_name
  }).then(function (result) {
    var is_invited = result.data.is_invited;

    if (is_invited === true) {
      return auth.createUserWithEmailAndPassword(email, password).then(function (userCredential) {
        // set authorization for this user for this Shiny app
        db.collection("apps").doc(app_name).collection("users").doc(email).set({
          invite_status: "accepted"
        }, {
          merge: true
        });
        return userCredential;
      }).then(function (userCredential) {
        // send verification email
        return userCredential.user.sendEmailVerification()["catch"](function (error) {
          console.error("Error sending email verification", error);
        });
      });
    } else {
      throw "You must have an invite to access this app";
    }
  }).then(function (obj) {
    $.LoadingOverlay("hide");
  })["catch"](function (error) {
    toastr.error("" + error);
    $.LoadingOverlay("hide");
    console.log("error registering user");
    console.log(error);
  });
});
$(document).on("click", "#reset_password", function () {
  var email = $("#email").val().toLowerCase();
  auth.sendPasswordResetEmail(email).then(function () {
    toastr.success("Password reset email sent to " + email);
  })["catch"](function (error) {
    toastr.error("" + error);
    console.log("error resetting email: ", error);
  });
}); // navigate between sign in and register pages

$(document).on("click", "#go_to_register", function () {
  $("#sign_in_panel").hide();
  $("#register_panel").show();
});
$(document).on("click", "#go_to_sign_in", function () {
  $("#register_panel").hide();
  $("#sign_in_panel").show();
});
$(document).on("click", "#submit_continue_register", function () {
  var email = $("#register_email").val().toLowerCase();
  $.LoadingOverlay("show", {
    fade: false,
    background: "rgba(255, 255, 255, 0.5)",
    text: "Checking Invite..."
  }); // `isUserInvited` will return `true` if the user is invited or `false` otherwise

  isUserInvited({
    email: email,
    app_name: app_name
  }).then(function (result) {
    if (result.data.is_invited === true) {
      // the user has been invited so allow the user to set their password and register
      $("#continue_registation").hide();
      $("#register_passwords").slideDown();
    } else {
      toastr.error("You must have an invite to access this app");
    }

    return null;
  }).then(function () {
    $.LoadingOverlay("hide");
  })["catch"](function (error) {
    $.LoadingOverlay("hide");
    toastr.error("" + error);
    console.log("error checking app 'users'");
    console.log(error);
  });
});
$("#email").on("keypress", function (e) {
  if (e.which == 13) {
    if ($("#submit_continue_sign_in").is(":visible")) {
      console.log("enter clicked email");
      $("#submit_continue_sign_in").click();
    } else {
      console.log("enter clicked email 2");
      $("#submit_sign_in").click();
    }
  }
});
$("#password").on('keypress', function (e) {
  if (e.which == 13) {
    $("#submit_sign_in").click();
  }
});
$("#register_email").on("keypress", function (e) {
  if (e.which == 13) {
    if ($("#submit_continue_register").is(":visible")) {
      $("#submit_continue_register").click();
    } else {
      $("#submit_register").click();
    }
  }
});
$("#register_password").on('keypress', function (e) {
  if (e.which == 13) {
    $("#submit_register").click();
  }
});
$("#register_password_verify").on('keypress', function (e) {
  if (e.which == 13) {
    $("#submit_register").click();
  }
});