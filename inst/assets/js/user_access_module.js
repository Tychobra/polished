"use strict";

var user_access_module = function user_access_module(ns_prefix) {
  $("#".concat(ns_prefix, "users_table")).on("click", ".sign_in_as_btn", function (e) {
    $(e.currentTarget).tooltip("hide");
    Shiny.setInputValue("".concat(ns_prefix, "sign_in_as_btn_user_uid"), e.currentTarget.id, {
      priority: "event"
    });
  });
  $("#".concat(ns_prefix, "users_table")).on("click", ".delete_btn", function (e) {
    $(e.currentTarget).tooltip("hide");
    Shiny.setInputValue("".concat(ns_prefix, "user_uid_to_delete"), e.currentTarget.id, {
      priority: "event"
    });
  });
  $("#".concat(ns_prefix, "users_table")).on("click", ".edit_btn", function (e) {
    $(e.currentTarget).tooltip("hide");
    Shiny.setInputValue("".concat(ns_prefix, "user_uid_to_edit"), e.currentTarget.id, {
      priority: "event"
    });
  }); // Delete User w/ Enter key

  $(document).on("keypress", function (e) {
    if (e.which == 13) {
      if ($("#".concat(ns_prefix, "submit_user_delete")).is(":visible")) {
        $("#".concat(ns_prefix, "submit_user_delete")).click();
      }
    }
  });
};