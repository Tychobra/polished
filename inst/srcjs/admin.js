var auth = firebase.auth()
var db = firebase.firestore()





$(document).on("shiny:sessioninitialized", function() {

  Shiny.addCustomMessageHandler(
    "polish__add_user",
    /*
    * @param messgae an object with the following properties
    * - email the users email address
    * - is_admin boolean whether or not the user is an admin
    * - role character string for a custom user group
    * - ns the namespace of the Shiny module
    */
    function(message) {

      var new_user = {
        email: message.email,
        is_admin: message.is_admin,
        role: message.role
      }

      const users_ref = db.collection("apps")
      .doc(app_name)
      .collection("users")

      users_ref.doc(new_user.email).get().then(user_doc => {


        if (user_doc.exists) {

          throw "user_already_exists"
          //return {type: "error", message: "the user already exists"}

        } else {

          // the user does not exist, so add the user doc to the "apps/{app_name}/users/" collection
          const timestamp = firebase.firestore.Timestamp.now()

          const is_admin_out = new_user.is_admin === "Yes" ? true : false

          return users_ref
            .doc(new_user.email)
            .set({
              email: new_user.email,
              is_admin: is_admin_out,
              role: new_user.role,
              invite_status: "pending",
              time_created: timestamp
            })

         }

      }).then(user => {

        toastr.success("User Successfully Invited")
        Shiny.setInputValue(message.ns + "polish__user_add_complete", 1, {priority: "event"})
        return null

      }).catch(error => {

        if (error === "user_already_exists") {
          toastr.error("Error: User Already Exists")
        } else {
          toastr.error("Error Inviting User")
        }

        console.log("error inviting user")
        console.log(error)
      })

    }
  )


  Shiny.addCustomMessageHandler(
    "polish__edit_user",
    /*
    * @param messgae an object with the following properties
    * - email the users email address
    * - is_admin boolean whether or not the user is an admin
    * - role character string for a custom user group
    * - ns the namespace of the Shiny module
    */
    function(message) {

      var new_user = {
        email: message.email,
        is_admin: message.is_admin,
        role: message.role
      }

      const users_ref = db.collection("apps")
      .doc(app_name) // TODO: update this to use app_name in config.yml
      .collection("users")


      const is_admin_out = new_user.is_admin === "Yes" ? true : false

      users_ref
      .doc(new_user.email)
      .set({
        is_admin: is_admin_out,
        role: new_user.role
      }, { merge: true }).then(user => {

        toastr.success("User Successfully Edited")
        Shiny.setInputValue(message.ns + "polish__user_edit_complete", 1, {priority: "event"})
        return null

      }).catch(error => {

        toastr.error("Error Editing User")
        console.log("error editing user")
        console.log(error)
      })

    }
  )


  Shiny.addCustomMessageHandler(
    "polish__delete_user",
    /*
    * @param messgae an object with the following properties
    * - email the users email address
    * - is_admin boolean whether or not the user is an admin
    * - role character string for a custom user group
    * - ns the namespace of the Shiny module
    */
    function(message) {


      const users_ref = db.collection("apps")
      .doc(app_name) // TODO: update this to use app_name in config.yml
      .collection("users")


      users_ref
      .doc(message.email)
      .delete().then(() => {

        toastr.success("User Successfully Deleted")
        Shiny.setInputValue(message.ns + "polish__user_delete_complete", 1, {priority: "event"})
        return null

      }).catch(error => {

        toastr.error("Error Deleting User")
        console.log("error deleting user")
        console.log(error)
      })

    }
  )


  Shiny.addCustomMessageHandler(
    "polish__get_users",
    function(message) {

      console.log("polish__get_users ran")

      db.collection("apps")
        .doc(app_name)
        .collection("users")
        .get().then((query_snapshot) => {

          let users = []

          query_snapshot.forEach((doc) => {
            users.push(doc.data())
          })

          users.forEach(user => {
            Object.keys(user).forEach((name) => {

            if (name === "time_created" | name == "time_last_signed_in") {
              // "time_last_signed_in" will be undefined if the user has not yet signed in
              if (user[name] !== undefined) {
                user[name] = user[name].toDate().toJSON()
              }

            }
          });

        })

        // TODO: use actual ns from Shiny
        Shiny.setInputValue("admin-user_access-polish__users:firestore_data_frame", users)

        return users
      }).catch(error => {
        console.error("error getting users", error)
      })
    }
  )


  Shiny.addCustomMessageHandler(
    "polish__get_roles",
    function(message) {

      db.collection("apps")
      .doc(app_name)
      .collection("roles")
      .get().then((query_snapshot) => {

        let roles = []

        query_snapshot.forEach((doc) => {
          roles.push(doc.data())
        })

        Shiny.setInputValue("admin-user_access-polish__user_roles", roles)

        return roles
      }).catch(error => {
        console.error("error getting users", error)
      })
    }
  )

})

$(document).on("click", "#polish__sign_out", () => {

  auth.signOut().catch(error => {
    console.error("sign out error: ", error)
  })

})
