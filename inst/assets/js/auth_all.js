"use strict";

var auth_all = function auth_all(ns_prefix) {
  $("#".concat(ns_prefix, "email")).on("keypress", function (e) {
    if (e.which == 13) {
      if ($("#".concat(ns_prefix, "sign_in_panel_top")).is(":visible")) {
        // user is on sign in page
        if ($("#".concat(ns_prefix, "submit_continue_sign_in")).is(":visible")) {
          $("#".concat(ns_prefix, "submit_continue_sign_in")).click();
        } else {
          $("#".concat(ns_prefix, "submit_sign_in")).click();
        }
      } else {
        // user is on register page
        if ($("#".concat(ns_prefix, "submit_continue_register")).is(":visible")) {
          $("#".concat(ns_prefix, "submit_continue_register")).click();
        } else {
          $("#".concat(ns_prefix, "submit_register")).click();
        }
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