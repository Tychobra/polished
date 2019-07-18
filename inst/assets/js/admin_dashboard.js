"use strict";

var dashboard_js = function dashboard_js(ns) {
  var db = firebase.firestore();
  var unsubscribe_sessions = db.collection("apps").doc(app_name).collection("sessions").onSnapshot(function (query_snapshot) {
    var sessions = [];
    query_snapshot.forEach(function (doc) {
      sessions.push(doc.data());
    }); //console.log("sessions: ", sessions)

    sessions.forEach(function (session) {
      session["time_created"] = session["time_created"].toDate().toJSON();
    });
    var shiny_id = ns + "polish__user_sessions:firestore_data_frame";
    Shiny.setInputValue(shiny_id, sessions);
  }, function (error) {
    console.log("Error listening for user sessions");
    console.log(error);
  });
  $(document).on('shiny:disconnected', function (socket) {
    unsubscribe_sessions();
  });
};