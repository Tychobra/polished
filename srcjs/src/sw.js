
// install event
self.addEventListener('install', evt => {
  console.log('sw installed')
})

// activate event
self.addEventListener('activate', evt => {
  console.log('sw activated')
})

setInterval(() => {

  fetch("/__keep_alive__").then(() => {
    console.log("I'm alive")
  }).catch(() => {
    console.log("I'm dead")
  })

}, 5000);


