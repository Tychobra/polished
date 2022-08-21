
window.addEventListener('load', async () => {


  if ('serviceWorker' in navigator) {


    try {

      const reg = await navigator.serviceWorker.register('/sw.js', {
        scope: "."
      })

      console.log('service worker registered', reg)

      if ('periodicSync' in reg) {


        const status = await navigator.permissions.query({
          name: 'periodic-background-sync',
        })

        console.log("status: ", status)


        //const permission = window.Notification.requestPermission().then(permission => {
        //console.log("permission: ", permission)
        const registration = await navigator.serviceWorker.ready;
        if (status.state === 'granted') {
          await registration.periodicSync.register('get-latest-news', {
            minInterval: 5 * 1000
          })

          console.log("periodic sync registered")
          const reg_tags = await registration.periodicSync.getTags()
          console.log("tags: ", reg_tags)

        }

      }

    } catch(err) {
      console.log("service worker error", err)
    }
  }

})
