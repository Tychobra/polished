"use strict";

var loading_text = function loading_text(text) {
  return {
    fade: false,
    background: "rgba(255, 255, 255, 1.0)",
    text: text,
    maxSize: 75
  };
};

var loading_options = loading_text("Authenticating...");