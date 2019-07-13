

var loading_options = {
  background: "rgba(255, 255, 255, 1.0)",
  text: "Authenticating..."
}



Shiny.addCustomMessageHandler(
  "polish__remove_loading",
  function(message) {
    $.LoadingOverlay("hide")
  }
)

Shiny.addCustomMessageHandler(
  "polish__show_loading",
  function(message) {
    $.LoadingOverlay("show", {
      text: message.text,
      background: "rgba(255, 255, 255, 1.0)"
    })
  }
)


