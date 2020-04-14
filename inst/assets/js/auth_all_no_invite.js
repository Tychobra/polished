"use strict";

var auth_all_no_invite = function auth_all_no_invite(ns_prefix) {
  $("#".concat(ns_prefix, "email")).on("keypress", function (e) {
    if (e.which == 13) {
      $("#".concat(ns_prefix, "submit_sign_in")).click();
    }
  });
  $("#".concat(ns_prefix, "password")).on('keypress', function (e) {
    if (e.which == 13) {
      $("#".concat(ns_prefix, "submit_sign_in")).click();
    }
  });
  $("#".concat(ns_prefix, "register_email")).on("keypress", function (e) {
    if (e.which == 13) {
      $("#".concat(ns_prefix, "submit_register")).click();
    }
  });
  $("#".concat(ns_prefix, "register_password")).on('keypress', function (e) {
    if (e.which == 13) {
      $("#".concat(ns_prefix, "submit_register")).click();
    }
  });
  $("#".concat(ns_prefix, "register_password_verify")).on('keypress', function (e) {
    if (e.which == 13) {
      $("#".concat(ns_prefix, "submit_register")).click();
    }
  });
};