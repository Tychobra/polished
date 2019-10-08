"use strict";

var loading_text = function loading_text(text) {
  return {
    fade: false,
    background: "rgba(255, 255, 255, 1.0)",
    text: text
  };
};

var loading_options = loading_text("Authenticating...");

var NS = function NS(ns_id) {
  var prefix = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : "#";
  return function (input_id) {
    return prefix + ns_id + "-" + input_id;
  };
};

var auth_all = function auth_all(ns_id) {
  var ns = NS(ns_id);
  var ns2 = NS(ns_id, "");
  $(ns("email")).on("keypress", function (e) {
    if (e.which == 13) {
      if ($(ns("submit_continue_sign_in")).is(":visible")) {
        $(ns("submit_continue_sign_in")).click();
      } else {
        $(ns("submit_sign_in")).click();
      }
    }
  });
  $(ns("password")).on('keypress', function (e) {
    if (e.which == 13) {
      $(ns("submit_sign_in")).click();
    }
  });
  $(ns("register_email")).on("keypress", function (e) {
    if (e.which == 13) {
      if ($(ns("submit_continue_register")).is(":visible")) {
        $(ns("submit_continue_register")).click();
      } else {
        $(ns("submit_register")).click();
      }
    }
  });
  $(ns("register_password")).on('keypress', function (e) {
    if (e.which == 13) {
      $(ns("submit_register")).click();
    }
  });
  $(ns("register_password_verify")).on('keypress', function (e) {
    if (e.which == 13) {
      $(ns("submit_register")).click();
    }
  });
};

Shiny.addCustomMessageHandler("polished__set_cookie", function (message) {
  Cookies.set('polished__token', message.polished_token);
  Shiny.setInputValue("polished__set_cookie_complete", 1, {
    priority: "event"
  });
});