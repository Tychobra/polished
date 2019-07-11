

var loading_options = {
  //background: "rgba(0, 0, 0, 0.8)",
  text: "Authenticating..."
}



Shiny.addCustomMessageHandler(
  "remove_loading",
  function(message) {
    $.LoadingOverlay("hide")
  }
)


