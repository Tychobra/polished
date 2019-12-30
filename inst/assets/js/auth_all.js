"use strict";

var NS = function NS(ns_id) {
  var prefix = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : "";
  return function (input_id) {
    return prefix + ns_id + "-" + input_id;
  };
};

var auth_all = function auth_all(ns_id) {
  var ns = NS(ns_id);
  var ns_pound = NS(ns_id, "#");
  $(ns_pound("email")).on("keypress", function (e) {
    if (e.which == 13) {
      if ($(ns_pound("submit_continue_sign_in")).is(":visible")) {
        $(ns_pound("submit_continue_sign_in")).click();
      } else {
        $(ns_pound("submit_sign_in")).click();
      }
    }
  });
  $(ns_pound("password")).on('keypress', function (e) {
    if (e.which == 13) {
      $(ns_pound("submit_sign_in")).click();
    }
  });
  $(ns_pound("register_email")).on("keypress", function (e) {
    if (e.which == 13) {
      if ($(ns_pound("submit_continue_register")).is(":visible")) {
        $(ns_pound("submit_continue_register")).click();
      } else {
        $(ns_pound("submit_register")).click();
      }
    }
  });
  $(ns_pound("register_password")).on('keypress', function (e) {
    if (e.which == 13) {
      $(ns_pound("submit_register")).click();
    }
  });
  $(ns_pound("register_password_verify")).on('keypress', function (e) {
    if (e.which == 13) {
      $(ns_pound("submit_register")).click();
    }
  });
  Shiny.addCustomMessageHandler(ns('remove_loading'), function (message) {
    $.LoadingOverlay("hide");
  });
};