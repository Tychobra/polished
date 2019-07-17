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

          let todays_date = new Date()
          todays_date = todays_date.setHours(0, 0, 0, 0)

          users.forEach(user => {
            Object.keys(user).forEach((name) => {

            if (name === "time_created" | name === "time_last_signed_in") {
              // "time_last_signed_in" will be undefined if the user has not yet signed in
              console.log("timestamp: ", user[name])
              if (user[name] !== undefined) {

                if (name === "time_last_signed_in") {
                  user.time_last_signed_in_r = user[name].toDate().toJSON()

                }

                let last_in_day = user[name].toDate().setHours(0, 0, 0, 0)
                if (last_in_day === todays_date) {
                  user[name] = user[name].toDate().toLocaleTimeString(
                    navigator.language,
                    { hour: 'numeric', minute: '2-digit' }
                  )
                } else {
                  user[name] = user[name].toDate().toLocaleDateString(
                    navigator.language
                  )
                }

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


  //Shiny.addCustomMessageHandler(
  //  "polish__get_roles",
  //  function(message) {
  //
  //    db.collection("apps")
  //    .doc(app_name)
  //    .collection("roles")
  //    .get().then((query_snapshot) => {
  //
  //      let roles = []
//
//        query_snapshot.forEach((doc) => {
//          roles.push(doc.data())
//        })
//
//        Shiny.setInputValue("admin-user_access-polish__user_roles", roles)
//
//        return roles
//      }).catch(error => {
//        console.error("error getting users", error)
//      })
//    }
//  )



  const unsubscribe_roles = db.collection("apps")
  .doc(app_name)
  .collection("roles")
  .onSnapshot((query_snapshot) => {

    let roles = []

    query_snapshot.forEach((doc) => {
      roles.push(doc.data())
    })

    Shiny.setInputValue("admin-user_access-polish__user_roles", roles)

    return roles
  }, error => {
    console.log("Error listening for user roles")
    console.log(error)
  })


  Shiny.addCustomMessageHandler(
    "polish__add_role",

    function(message) {

      const roles_ref = db.collection("apps")
      .doc(app_name)
      .collection("roles")

      roles_ref.get().then(role => {

        if (role.exists) {
          throw "role_already_exists"
        } else {

          return roles_ref.doc(message.role).set({
            role: message.role
          })

        }

      }).catch(error => {

        if (error === "role_already_exists") {
          // Shiny checks if the role exists before calling 'polish__add_role', so
          // this error should only occur if user is directly manipulating the js.
          // TODO: may want to log this to Sentry with user info
          toastr.error("Error Role Already Exists")
        } else {
          toastr.error("Error Adding User Role")
        }


        console.log("error adding user role")
        console.log(error)
      })

    }
  )

  // TODO: figure out if this is properly unsubscribing from the roles listener
  $(document).on('shiny:disconnected', function(socket) {
    //console.log('Shiny Disconnected')
    if (typeof unsubscribe_roles !== undefined) {
      unsubscribe_roles()
    }
  })

  Shiny.addCustomMessageHandler(
    "polish__delete_role",
    /*
    * @param messgae an object with the following properties
    * - email the users email address
    * - is_admin boolean whether or not the user is an admin
    * - role character string for a custom user group
    * - ns the namespace of the Shiny module
    */
    function(message) {


      const roles_ref = db.collection("apps")
      .doc(app_name)
      .collection("roles")


      roles_ref
      .doc(message.role)
      .delete().then(() => {
        // TODO: need to delete role from each user with the role.  This needs to be done in a Firebase function

        toastr.success("Role Successfully Deleted")

        return null

      }).catch(error => {

        toastr.error("Error Deleting Role")
        console.log("error deleting role")
        console.log(error)
      })

    }
  )

})
