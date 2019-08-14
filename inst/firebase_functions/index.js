/*
*
* version 0.0.3
* last updated 2019-08-12
* bump the above version and change the last updated date whenever a change
* is made to this file
*
*/
const functions = require('firebase-functions')
const admin = require('firebase-admin')


admin.initializeApp();

const db = admin.firestore();



exports.signInWithToken = functions.https.onRequest(async (req, res) => {

  const auth_token = req.query.token
  const app_name = req.query.app_name

  // the firebase user
  let user = null
  // the user object to return to the shiny app
  let user_out = null
  try {
    // verify the auth_token to sign the user into Shiny
    user = await admin.auth().verifyIdToken(auth_token)

    const user_ref = db.collection("apps")
      .doc(app_name)
      .collection("users")
      .doc(user.email)

    const app_user = await user_ref.get()

    if (app_user.exists) {
      // user document exists, so the user is either a newly invited user or already a user of the app
      user_out = await app_user.data()

      // update time last_signed_in
      const timestamp = admin.firestore.FieldValue.serverTimestamp()
      user_ref.set({
        time_last_signed_in: timestamp
      }, { merge: true })

      // if this is the first time the user has accessed the app, the "invite_status" property will be
      // "pending", and we need to switch it to accepted
      if (user_out.invite_status === "pending") {

        user_ref.set({
          invite_status: "accepted"
        }, { merge: true })

      }

      user_out.email_verified = user.email_verified
      user_out.uid = user.uid

      const new_session = {
        email: user_out.email,
        app_name: app_name,
        time_created: timestamp
      }

      // add the session document to "apps/{app_name}/sessions/"
      db.collection("apps")
      .doc(app_name)
      .collection("sessions")
      .add(new_session)

      res.status(200).send(JSON.stringify(user_out))

    } else {
      res.status(500).send(JSON.stringify(user_out))
    }

  } catch(error) {
    console.error("auth_error: ", error)
    res.status(500).send(JSON.stringify(user_out))
  }

})

/* used to recheck email verification
*
* When user originally registers, they are taken to the email verification page.
* When they refresh that page, this function runs, rechecking if their email
* has been verified yet.  If it has been verified, they move on to the app + admin
* pages
*/
exports.getUser = functions.https.onRequest(async (req, res) => {
  // TODO: this needs to require a JWT
  const uid = req.query.uid

  // the firebase user
  let user = null

  try {
    // verify the auth_token to sign the user into Shiny
    user = await admin.auth().getUser(uid)
    res.status(200).send(JSON.stringify(user))
  } catch(error) {

    user = null

    console.log("error getting user ", error)
    res.status(500).send(JSON.stringify(user))
  }

})





const check_string = (string) => {
  if (!(typeof string === 'string') || string.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid Argument');
  }
}
// check whether or not the user is invited
// return `true` if the user is invited and `false` if not
exports.isUserInvited = functions.https.onCall(async (data, context) => {

  const email = data.email
  const app_name = data.app_name

  check_string(email)
  check_string(app_name)

  // check that the user requesting to sign in as another user is an admin
  const req_user = db.collection("apps")
  .doc(app_name)
  .collection("users")
  .doc(email)



  return req_user.get().then(user_doc => {
    let is_invited = null
    if (user_doc.exists) {
      is_invited = true
    } else {
      is_invited = false
    }

    // user is an admin
    return {
      is_invited
    }
  })



})


/*
* when a role is deleted, we need to remove that role from any users that
* have the role
*
*
*/
exports.deleteUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
      'while authenticated.');
  }
  // TODO: also check if user is an admin here

  const app_name = data.app_name
  const role = data.role

  const users_ref = db.collection("apps")
  .doc(app_name)
  .collection("users")
  .where("role", "==", role)

  const roles_ref = db.collection("apps")
  .doc(app_name)
  .collection("roles")
  .doc(role)

  return db.runTransaction(transaction => {

    return transaction.get(users_ref).then(query_snapshot => {

      // delete the role from each user that has the role
      query_snapshot.forEach(doc => {
        console.log("doc_data: ", doc.data())
        transaction.update(doc.ref, {
          role: ""
        })

      })

      // delete the role from the "roles" collection
      transaction.delete(roles_ref)
    })

  }).then(() => {
    console.log("success: role deleted from users: ")
    return { message: "success" }
  }).catch(error => {
    console.log("error: error deleting role from users: ", error)
    return { message: "error" }
  })
})



exports.addFirstUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
      'while authenticated.');
  }

  const email = data.email
  const app_name = data.app_name


  // check to make sure that this is in fact the first user
  const users_ref = db.collection("apps")
  .doc(app_name)
  .collection("users")

  return users_ref
  .get().then(snapshot => {

    // if a user already exists for this app then throw an error
    if (!snapshot.empty) {
       throw new functions.https.HttpsError('failed-precondition', 'This must be the first user');
    }

    return null
  }).then(() => {

    return users_ref
    .doc(email).set({
      email: email,
      is_admin: true,
      time_created: admin.firestore.FieldValue.serverTimestamp(),
      invite_status: "accepted",
      app_name: app_name
    })

  }).then(() => {
    return {
      message: "success"
    }
  })
  .catch(error => {
    console.log("error creating first user: ", error)
    return {
      message: "error"
    }
  })

})