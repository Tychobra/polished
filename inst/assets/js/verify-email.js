"use strict";

$(document).on("click", "#resend_verification_email", function () {
  var user = auth.currentUser;
  user.sendEmailVerification().then(function () {// TODO: add toast
  })["catch"](function (error) {
    // TODO: toast
    console.error('error sending email verification', error);
  });
});