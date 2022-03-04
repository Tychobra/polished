"use strict";

$(document).on("shiny:sessioninitialized", function () {
  Shiny.addCustomMessageHandler("create_qrcode", function (message) {
    var qrcode = new QRCode(document.getElementById("qrcode"), message.url);
  });
  document.getElementById("two_fa_code").focus();
});