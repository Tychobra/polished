"use strict";

var loading_options = {
  fade: false,
  background: "rgba(255, 255, 255, 1.0)",
  text: "Authenticating..."
};

if (typeof toastr !== "undefined") {
  toastr.options.positionClass = "toast_bottom_center";
}

Shiny.addCustomMessageHandler("polish__remove_loading", function (message) {
  $.LoadingOverlay("hide");
});
Shiny.addCustomMessageHandler("polish__show_loading", function (message) {
  $.LoadingOverlay("show", {
    fade: false,
    background: "rgba(255, 255, 255, 1.0)",
    text: message.text
  });
});