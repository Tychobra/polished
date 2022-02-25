"use strict";

var two_fa_module = function two_fa_module(ns_prefix) {
  Shiny.addCustomMessageHandler(ns_prefix + "create_qrcode", function (message) {
    var qrcode = new QRCode(document.getElementById(ns_prefix + "qrcode"), message.url);
  });
  $(document).ready(function () {
    document.getElementById(ns_prefix + "two_fa_code").focus();
  });
};