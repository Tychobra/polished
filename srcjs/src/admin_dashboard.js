

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

    sessions.forEach(session => {
      session["time_created"] = session["time_created"].toDate().toJSON()
    })


    const shiny_id = ns + "polish__user_sessions:firestore_data_frame"
    Shiny.setInputValue(shiny_id, sessions)

  }, error => {
    console.log("Error listening for user sessions")
    console.log(error)
  })

  $(document).on('shiny:disconnected', function(socket) {

    unsubscribe_sessions()

  })
}
