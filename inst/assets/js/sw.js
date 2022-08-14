"use strict";

// install event
self.addEventListener('install', function (evt) {
  console.log('sw installed');
}); // activate event

self.addEventListener('activate', function (evt) {
  console.log('sw activated');
});
setInterval(function () {
  fetch("/__keep_alive__").then(function () {
    console.log("I'm alive");
  })["catch"](function () {
    console.log("I'm dead");
  });
}, 5000);