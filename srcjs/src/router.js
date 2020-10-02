// force page reload after browser back and forward buttons are clicked
window.onpopstate = (event) => {

  // Check if popstate was caused by queryString (not hash change)
  if (window.location.hash == "") {
    window.location.reload(true);
  }
};
