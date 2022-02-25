
const two_fa_module = (ns_prefix) => {

  Shiny.addCustomMessageHandler(
    ns_prefix + "create_qrcode",
    (message) => {

      var qrcode = new QRCode(
        document.getElementById(ns_prefix + "qrcode"),
        message.url
      )

    }
  )

  $(document).ready(() => {
    document.getElementById(ns_prefix + "two_fa_code").focus();
  })

}


