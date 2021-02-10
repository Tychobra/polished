"use strict";

// force page reload after browser back and forward buttons are clicked
window.onpopstate = function (event) {
  window.location.reload(true);
}; // update Shiny input 3 minutes to keep Shiny session from graying out as long as
// browser tab is open for the app.


(function () {
  var socket_timeout_interval;
  var n = 0;
  $(document).on('shiny:connected', function (event) {
    socket_timeout_interval = setInterval(function () {
      Shiny.setInputValue('polished__alive_count', n++, {
        event: 'priority'
      });
    }, 3 * 60 * 1000);
  });
  $(document).on('shiny:disconnected', function (event) {
    clearInterval(socket_timeout_interval);
  });
})();