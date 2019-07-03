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

//const addUserAuthorization = async (context) => {
//
//  // first time user registration so set up the doc for this user
//  // in the "users" collection
//  const uid = context.auth.uid
//  const email = context.auth.token.email
//  const timestamp = admin.firestore.FieldValue.serverTimestamp()
//
//  const role_ref = await db.collection("apps")
//    .doc(process.env.SHINY_APP_NAME)
//    .collection("invites")
//    .doc(email).get()
//
//  const role = role_ref.data().role
//
//  db.collection("users").doc(uid).set({
//    email: email,
//    app_name: process.env.SHINY_APP_NAME,
//    time_created: timestamp,
//    role: role
//  })
//
//}

//exports.registerSetup = functions.https.onCall(async (data, context) => {
//
//  const email = context.auth.token.email
//
//  // check if the user already has a document in the "users" collection
//  const user_doc = await db.collection("users").doc(email).get()
//
//  if (user_doc.exists) {
//
//    // check if the user is already authorized to access this app
//    const user_data = user_doc.data()
//
//    console.log("user_data: ", user_data)
//
//  } else {
//
//
//    addUserAuthorization(context)
//  }
//
//
//})


//exports.addUser = functions.https.onRequest(async (req, res) => {
//
//  const is_admin = db.collection("apps")
//  .doc(process.env.SHINY_APP_NAME)
//  .collection("users")
//  .doc()
//
//  console.log("body: ", req.body)
//
//  res.send("howdy")
//})

exports.addUser = functions.https.onCall(async (data, context) => {

  console.log("auth: ", context.auth)

  const req_user_email = context.auth.token.email

  const new_user = data.data

  console.log("new_user: ", new_user)


  const users_ref = await db.collection("apps")
    .doc(process.env.SHINY_APP_NAME)
    .collection("users")

  // check that the user adding this user is an admin
  const req_user = await users_ref
    .doc(req_user_email)
    .get()

  const is_admin = await req_user.data().is_admin

  if (is_admin === true) {
    // check if the user already exists
    const existing_new_user = await users_ref
      .doc(new_user.email)

    if (existing_new_user.exists) {

      return {type: "error", message: "the user already exists"}

    } else {

      // the user does not exist, so add the user doc to the "apps/{app_name}/users/" collection
      const timestamp = admin.firestore.FieldValue.serverTimestamp()

      const is_admin_out = new_user.is_admin === "Yes" ? true : false

      const new_user_out = await users_ref
      .doc(new_user.email)
      .set({
        email: new_user.email,
        is_admin: is_admin_out,
        role: new_user.role,
        invite_status: "pending",
        time_created: timestamp
      })

      return new_user_out
    }

  } else {

    // throw an error
    throw new functions.https.HttpsError('failed-authorization', 'You must be an admin to add a user');
  }

})

