"use strict";

var auth = firebase.auth();
$(document).on("click", "#resend_verification_email", function () {
  var user = auth.currentUser;
  console.log("current_user: ", user);
  user.sendEmailVerification().then(function () {
    toastr.success("Verification Email Send to " + user.email);
  })["catch"](function (error) {
    toastr.error("Error sending email verification");
    console.error("Error sending email verification", error);
  });
});