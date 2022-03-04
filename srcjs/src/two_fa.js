
$(document).on("shiny:sessioninitialized", () => {
  Shiny.addCustomMessageHandler(
    "create_qrcode",
    (message) => {

      var qrcode = new QRCode(
        document.getElementById("qrcode"),
        message.url
      )

    }
  )

  document.getElementById("two_fa_code").focus();
})
