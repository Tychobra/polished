
// install event
self.addEventListener('install', evt => {
  console.log('sw installed')
})

// activate event
self.addEventListener('activate', evt => {
  console.log('sw activated')
})

self.addEventListener('periodicsync', (event) => {

  console.log("periodic sync event fired: ", event.tag)
  if (event.tag === 'get-latest-news') {
    //event.waitUntil();
    fetch("/__keep_alive__").then((res) => {
      console.log("I'm alive: ", res.json())
    }).catch((err) => {
      console.log("I'm dead: ", err)
    })
  }
})


