var db = firebase.firestore()
var functions = firebase.functions()




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
        email: message.email.toLowerCase(),
        is_admin: message.is_admin,
        role: message.role
      }


      // the user does not exist, so add the user doc to the "apps/{app_name}/users/" collection
      const timestamp = firebase.firestore.Timestamp.now()

      const users_ref = db.collection("apps")
      .doc(app_name)
      .collection("users")
      .doc(new_user.email)
      .set({
        email: new_user.email,
        is_admin: new_user.is_admin,
        role: new_user.role,
        invite_status: "pending",
        time_created: timestamp
      }).then(user => {

        toastr.success("User Successfully Invited")
        return null

      }).catch(error => {

        toastr.error("Error Inviting User")
        console.log("Error Inviting User")
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
        email: message.email.toLowerCase(),
        is_admin: message.is_admin,
        role: message.role
      }

      const users_ref = db.collection("apps")
      .doc(app_name) // TODO: update this to use app_name in config.yml
      .collection("users")

      users_ref
      .doc(new_user.email)
      .set({
        is_admin: new_user.is_admin,
        role: new_user.role
      }, { merge: true }).then(user => {

        toastr.success("User Successfully Edited")
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

      const email = message.email.toLowerCase()

      const users_ref = db.collection("apps")
      .doc(app_name) // TODO: update this to use app_name in config.yml
      .collection("users")


      users_ref
      .doc(email)
      .delete().then(() => {

        toastr.success("User Successfully Deleted")
        return null

      }).catch(error => {

        toastr.error("Error Deleting User")
        console.log("error deleting user")
        console.log(error)
      })

    }
  )




  const unsubscribe_users = db.collection("apps")
  .doc(app_name)
  .collection("users")
  .onSnapshot((query_snapshot) => {
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
  }, error => {
    console.error("error getting users", error)
  })


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

  $(document).on('shiny:disconnected', function(socket) {
    // TODO: fire this manully whenever user goes from admin panel to Shiny app?
    console.log('users listener about to be removed')

    unsubscribe_users()
    unsubscribe_roles()
  })

  Shiny.addCustomMessageHandler(
    "polish__add_role",

    function(message) {

      const roles_ref = db.collection("apps")
      .doc(app_name)
      .collection("roles")
      .doc(message.role)
      .set({
        role: message.role
      }).then(() => {
        toastr.success("Role Successfully Added")
      }).catch(error => {

        toastr.error("Error Adding User Role")

        console.log("Error Adding User Role")
        console.log(error)
      })



    }
  )

  const deleteUserRole  = functions.httpsCallable("deleteUserRole")
  Shiny.addCustomMessageHandler(
    "polish__delete_role",

    function(message) {
      deleteUserRole({ role: message.role, app_name: app_name }).then(result => {
        toastr.success("Role Successfully Deleted")
      }).catch(error => {
        toastr.success("Error Deleting Role")
        console.log("Error Deleting Role")
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
})
