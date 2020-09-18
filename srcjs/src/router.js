// force page reload after browser back and forward buttons are clicked
window.onpopstate = (event) => {
  window.location.reload(true)
}
