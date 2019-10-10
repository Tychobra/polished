"use strict";

var loading_text = function loading_text(text) {
  return {
    fade: false,
    background: "rgba(255, 255, 255, 1.0)",
    text: text
  };
};

var loading_options = loading_text("Authenticating...");