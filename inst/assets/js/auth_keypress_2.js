"use strict";

var auth_keypress = function auth_keypress(ns_prefix) {
  $("#".concat(ns_prefix, "email")).on("keypress", function (e) {
    if (e.which == 13) {
      if ($("#".concat(ns_prefix, "submit_continue_sign_in")).is(":visible")) {
        $("#".concat(ns_prefix, "submit_continue_sign_in")).click();
      } else {
        $("#".concat(ns_prefix, "submit_sign_in")).click();
      }
    }
  });
  $("#".concat(ns_prefix, "email_register")).on("keypress", function (e) {
    if (e.which == 13) {
      if ($("#".concat(ns_prefix, "submit_continue_register")).is(":visible")) {
        $("#".concat(ns_prefix, "submit_continue_register")).click();
      } else {
        $("#".concat(ns_prefix, "submit_register")).click();
      }
    }
  });
  $("#".concat(ns_prefix, "password")).on('keypress', function (e) {
    if (e.which == 13) {
      $("#".concat(ns_prefix, "submit_sign_in")).click();
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