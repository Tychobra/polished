"use strict";

function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

var db = firebase.firestore();
$(document).on("shiny:sessioninitialized", function () {
  Shiny.addCustomMessageHandler("polish__add_user",
  /*
  * @param messgae an object with the following properties
  * - email the users email address
  * - is_admin boolean whether or not the user is an admin
  * - role character string for a custom user group
  * - ns the namespace of the Shiny module
  */
  function (message) {
    var new_user = {
      email: message.email.toLowerCase(),
      is_admin: message.is_admin,
      role: message.role // the user does not exist, so add the user doc to the "apps/{app_name}/users/" collection

    };
    var timestamp = firebase.firestore.Timestamp.now();
    var users_ref = db.collection("apps").doc(app_name).collection("users").doc(new_user.email).set({
      email: new_user.email,
      is_admin: new_user.is_admin,
      role: new_user.role,
      invite_status: "pending",
      time_created: timestamp
    }).then(function (user) {
      toastr.success("User Successfully Invited");
      return null;
    })["catch"](function (error) {
      toastr.error("Error Inviting User");
      console.log("Error Inviting User");
      console.log(error);
    });
  });
  Shiny.addCustomMessageHandler("polish__edit_user",
  /*
  * @param messgae an object with the following properties
  * - email the users email address
  * - is_admin boolean whether or not the user is an admin
  * - role character string for a custom user group
  * - ns the namespace of the Shiny module
  */
  function (message) {
    var new_user = {
      email: message.email.toLowerCase(),
      is_admin: message.is_admin,
      role: message.role
    };
    var users_ref = db.collection("apps").doc(app_name) // TODO: update this to use app_name in config.yml
    .collection("users");
    users_ref.doc(new_user.email).set({
      is_admin: new_user.is_admin,
      role: new_user.role
    }, {
      merge: true
    }).then(function (user) {
      toastr.success("User Successfully Edited");
      return null;
    })["catch"](function (error) {
      toastr.error("Error Editing User");
      console.log("error editing user");
      console.log(error);
    });
  });
  Shiny.addCustomMessageHandler("polish__delete_user",
  /*
  * @param messgae an object with the following properties
  * - email the users email address
  * - is_admin boolean whether or not the user is an admin
  * - role character string for a custom user group
  * - ns the namespace of the Shiny module
  */
  function (message) {
    var email = message.email.toLowerCase();
    var users_ref = db.collection("apps").doc(app_name) // TODO: update this to use app_name in config.yml
    .collection("users");
    users_ref.doc(email)["delete"]().then(function () {
      toastr.success("User Successfully Deleted");
      return null;
    })["catch"](function (error) {
      toastr.error("Error Deleting User");
      console.log("error deleting user");
      console.log(error);
    });
  });
  var unsubscribe_users = db.collection("apps").doc(app_name).collection("users").onSnapshot(function (query_snapshot) {
    var users = [];
    query_snapshot.forEach(function (doc) {
      users.push(doc.data());
    });
    var todays_date = new Date();
    todays_date = todays_date.setHours(0, 0, 0, 0);
    users.forEach(function (user) {
      Object.keys(user).forEach(function (name) {
        if (name === "time_created" | name === "time_last_signed_in") {
          // "time_last_signed_in" will be undefined if the user has not yet signed in
          if (user[name] !== undefined) {
            if (name === "time_last_signed_in") {
              user.time_last_signed_in_r = user[name].toDate().toJSON();
            }

            var last_in_day = user[name].toDate().setHours(0, 0, 0, 0);

            if (last_in_day === todays_date) {
              user[name] = user[name].toDate().toLocaleTimeString(navigator.language, {
                hour: 'numeric',
                minute: '2-digit'
              });
            } else {
              user[name] = user[name].toDate().toLocaleDateString(navigator.language);
            }
          }
        }
      });
    }); // TODO: use actual ns from Shiny

    Shiny.setInputValue("admin-user_access-polish__users:firestore_data_frame", users);
    return users;
  }, function (error) {
    console.error("error getting users", error);
  });
  var unsubscribe_roles = db.collection("apps").doc(app_name).collection("roles").onSnapshot(function (query_snapshot) {
    var roles = [];
    query_snapshot.forEach(function (doc) {
      roles.push(doc.data());
    });
    Shiny.setInputValue("admin-user_access-polish__user_roles", roles);
    return roles;
  }, function (error) {
    console.log("Error listening for user roles");
    console.log(error);
  });
  $(document).on('shiny:disconnected', function (socket) {
    // TODO: fire this manully whenever user goes from admin panel to Shiny app?
    console.log('users listener about to be removed');
    unsubscribe_users();
    unsubscribe_roles();
  });
  Shiny.addCustomMessageHandler("polish__add_role", function (message) {
    var roles_ref = db.collection("apps").doc(app_name).collection("roles").doc(message.role).set({
      role: message.role
    }).then(function () {
      toastr.success("Role Successfully Added");
    })["catch"](function (error) {
      toastr.error("Error Adding User Role");
      console.log("Error Adding User Role");
      console.log(error);
    });
  }); // TODO: figure out if this is properly unsubscribing from the roles listener

  $(document).on('shiny:disconnected', function (socket) {
    //console.log('Shiny Disconnected')
    if (_typeof(unsubscribe_roles) !== undefined) {
      unsubscribe_roles();
    }
  });
});