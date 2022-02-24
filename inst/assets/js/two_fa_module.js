"use strict";

var two_fa_module = function two_fa_module(ns_prefix) {
  Shiny.addCustomMessageHandler(ns_prefix + "create_qrcode", function (message) {
    debugger;
    var qrcode = new QRCode(document.getElementById(ns_prefix + "qrcode"));
    qrcode.makeCode(message.url); //,
    //width: 128,
    //height: 128,
    //colorDark : "#5868bf",
    //colorLight : "#ffffff",
    //correctLevel : QRCode.CorrectLevel.H
    //});
  });
};