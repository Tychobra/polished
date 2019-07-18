


const dashboard_js = (ns) => {
  const db = firebase.firestore()

  const unsubscribe_sessions = db.collection("apps")
  .doc(app_name)
  .collection("sessions")
  .onSnapshot((query_snapshot) => {

    let sessions = []

    query_snapshot.forEach((doc) => {
      sessions.push(doc.data())
    })

    //console.log("sessions: ", sessions)

    sessions.forEach(session => {

      Object.keys(session).forEach((name) => {
        // check if property is an instance of a Firestore Timestamp
        if (session[name].constructor.name === "n") {
          session[name] = session[name].toDate().toJSON()
        }
      })

    })


    const shiny_id = ns + "polish__user_sessions:firestore_data_frame"
    console.log("shiny_id: ", shiny_id)
    Shiny.setInputValue(shiny_id, sessions)

  }, error => {
    console.log("Error listening for user sessions")
    console.log(error)
  })

  $(document).on('shiny:disconnected', function(socket) {

    unsubscribe_sessions()

  })
}
