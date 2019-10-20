"use strict";

var auth = firebase.auth();
$(document).on("click", "#resend_verification_email", function () {
  var user = auth.currentUser;
  console.log("current_user: ", user);
  user.sendEmailVerification().then(function () {
    toastr.success("Verification email sent to " + user.email, null, toast_options);
  })["catch"](function (error) {
    toastr.error("Error: " + error.message, null, toast_options);
    console.error("Error sending email verification", error);
  });
});