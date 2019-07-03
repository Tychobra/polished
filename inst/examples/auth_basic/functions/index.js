const functions = require('firebase-functions')
const admin = require('firebase-admin')

// attach the variables defined in ".env" to `process.env`
require('dotenv').config()

admin.initializeApp();

const db = admin.firestore();

exports.signInWithToken = functions.https.onRequest(async (req, res) => {

  const auth_token = req.query.token

  // the firebase user
  let user = null
  // the user object to return to the shiny app
  let user_out = null
  try {
    // verify the auth_token to sign the user into Shiny
    user = await admin.auth().verifyIdToken(auth_token)
    console.log("user: ", user)
    const user_ref = db.collection("apps")
      .doc(process.env.SHINY_APP_NAME)
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

    } else {

      res.send("Not Invited")
    }



    user_out.email_verified = user.email_verified
    user_out.uid = user.uid

  } catch(error) {
    user_out = null
    console.log("auth_error: ", error)
  }

  res.send(JSON.stringify(user_out))
})

exports.getUser = functions.https.onRequest(async (req, res) => {

  const uid = req.query.uid

  // the firebase user
  let user = null

  try {
    // verify the auth_token to sign the user into Shiny
    user = await admin.auth().getUser(uid)
    console.log("user: ", user)

  } catch(error) {

    user = null

    console.log("error getting user ", error)
  }

  res.send(JSON.stringify(user))
})
