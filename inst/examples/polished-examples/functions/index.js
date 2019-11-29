/*
*
* version 0.0.7
* last updated 2019-11-15
* bump the above version and change the last updated date whenever a change
* is made to this file
*
*/
const functions = require('firebase-functions')
const admin = require('firebase-admin')


admin.initializeApp();




exports.sign_in_firebase = functions.https.onRequest(async (req, res) => {

  const auth_token = req.query.token

  // the firebase user
  let user = null
  // the user object to return to the shiny app
  try {
    // verify the auth_token to sign the user into Shiny
    user = await admin.auth().verifyIdToken(auth_token)

    res.status(200).send(JSON.stringify(user))

  } catch(error) {
    console.error("auth_error: ", error)
    res.status(500).send(null)
  }
})


/* used to recheck email verification
*
* When user originally registers, they are taken to the email verification page.
* When they refresh that page, this function runs, rechecking if their email
* has been verified yet.  If it has been verified, they move on to the app + admin
* pages
*/
exports.get_user = functions.https.onRequest(async (req, res) => {

  const uid = req.query.uid

  try {

    const user_out = await admin.auth().getUser(uid)
    res.status(200).send(JSON.stringify(user_out.emailVerified))

  } catch(error) {

    console.log("error getting user ", error)
    res.status(500).send(JSON.stringify(null))
  }

})
