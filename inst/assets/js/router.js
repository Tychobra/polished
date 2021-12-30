"use strict";

// force page reload after browser back and forward buttons are clicked
(function () {
  // get the polished page from the "page" query parameter
  var get_polished_page = function get_polished_page() {
    var queryString = window.location.search;
    var urlParams = new URLSearchParams(queryString);
    return urlParams.get('page');
  }; // get the initial polished page


  var polished_page_prev = get_polished_page(); // the following onpopstate event handler allows users to use forward and back buttons to navigate between
  // polished admin panel, the shiny app, and other shiny apps within the same polished app (e.g. payments) using
  // the forward and back buttons.  It also checks the query string to only refresh the app if the user is in fact
  // navigating between polished apps and not doing something like changing the url hash or query parameters.

  window.onpopstate = function (event) {
    var query_string = window.location.search;
    var url_params = new URLSearchParams(query_string);
    var polished_page = url_params.get('page');

    if (polished_page !== null || polished_page_prev !== null && polished_page === null) {
      window.location.reload(true);
      polished_page_prev = polished_page;
    }
  };
})();