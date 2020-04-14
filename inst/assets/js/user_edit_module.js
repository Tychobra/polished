"use strict";

var user_edit_module = function user_edit_module(ns_prefix) {
  $(document).on("keypress", function (e) {
    if (e.which == 13) {
      if ($("#".concat(ns_prefix, "submit")).is(":visible")) {
        $("#".concat(ns_prefix, "submit")).click();
      }
    }
  });
};