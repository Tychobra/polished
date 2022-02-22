
const two_fa_module = (ns_prefix) => {

  Shiny.addCustomMessageHandler(
    ns_prefix + "create_qrcode",
    function(message) {

      var qrcode = new QRCode(document.getElementById(ns_prefix + "qrcode"), {
      	text: message.base_32_secret,
      	//width: 128,
      	//height: 128,
      	//colorDark : "#5868bf",
  	//colorLight : "#ffffff",
  	//correctLevel : QRCode.CorrectLevel.H
  });
    }
  )


}


