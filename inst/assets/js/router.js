"use strict";

// force page reload after browser back and forward buttons are clicked
window.onpopstate = function (event) {
  window.location.reload(true);
};