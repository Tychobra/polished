"use strict";

// force page reload after browser back and forward buttons are clicked
window.onpopstate = function (event) {
  window.location.reload(true);
}; // ping server every 3 minutes to keep Shiny session from graying out as long as
// browser tab is open for the app.


$(function () {
  function keepAlive() {
    var httpRequest = new XMLHttpRequest();
    httpRequest.open('GET', "/polish/js/router.js");
    httpRequest.send(null);
  }

  setInterval(keepAlive, 3 * 60 * 1000);
});