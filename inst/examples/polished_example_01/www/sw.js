"use strict";

// install event
self.addEventListener('install', function (evt) {
  console.log('sw installed');
}); // activate event

self.addEventListener('activate', function (evt) {
  console.log('sw activated');
});

self.addEventListener('periodicsync', function (event) {
  console.log("periodic sync event fired: ", event.tag);

  if (event.tag === 'get-latest-news') {
    //event.waitUntil();

    try {
      const res = fetch("/?stay-alive=true")
      console.log("I'm alive")
    } catch(err) {
      console.log("I'm dead: ", err);
    }

  }
});


self.addEventListener('fetch', function(event) {
   event.respondWith(async function() {
      try{
        var res = await fetch(event.request);
        var cache = await caches.open('cache');
        cache.put(event.request.url, res.clone());
        return res;
      }
      catch(error){
        return caches.match(event.request);
       }
     }());
 });