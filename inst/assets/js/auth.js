"use strict";

var db = firebase.firestore();

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
  var email = $('#email').val();
  does_email_exist(email).then(function (t_f) {
    if (t_f === true) {
      // TODO: could check invite or registration status here to see if the user is already
      // registered.  probably not worth it at the moment since it may get out of sync with actual
      // firebase auth registered users
      // the user has been invited so allow the user to set their password and register
      $("#continue_sign_in").hide();
      $("#sign_in_password").slideDown();
    } else {
      toastr.error("You must have an invite to access this app");
    }

    return null;
  })["catch"](function (error) {
    toastr.error("" + error);
    console.log("error checking app 'users'");
    console.log(error);
  });
});
$(document).on('click', '#submit_sign_in', function () {
  $.LoadingOverlay("show", loading_options);
  var email = $('#email').val();
  var password = $('#password').val(); // check that user has an invite

  does_email_exist(email).then(function (t_f) {
    if (t_f === true) {
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
  var email = $("#register_email").val();
  var password = $("#register_password").val();
  var password_2 = $("#register_password_verify").val();

  if (password !== password_2) {
    toastr.error("The passwords do not match");
    return;
  }

  $.LoadingOverlay("show", loading_options); // double check that the email is in "invites" collection

  db.collection("apps").doc(app_name).collection("users").doc(email).get().then(function (doc) {
    if (doc.exists) {
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
    $.LoadingOverlay("hide", loading_options);
  })["catch"](function (error) {
    toastr.error("" + error);
    $.LoadingOverlay("hide", loading_options);
    console.log("error registering user");
    console.log(error);
  });
});
$(document).on("click", "#reset_password", function () {
  var email = $("#email").val();
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
  var email = $("#register_email").val();
  does_email_exist(email).then(function (t_f) {
    if (t_f === true) {
      // TODO: could check invite or registration status here to see if the user is already
      // registered.  probably not worth it at the moment since it may get out of sync with actual
      // firebase auth registered users
      // the user has been invited so allow the user to set their password and register
      $("#continue_registation").hide();
      $("#register_passwords").slideDown();
    } else {
      toastr.error("You must have an invite to access this app");
    }

    return null;
  })["catch"](function (error) {
    toastr.error("" + error);
    console.log("error checking app 'users'");
    console.log(error);
  });
});