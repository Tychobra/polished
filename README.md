# polished

enhance Shiny apps with modern front end web services

## Getting Started

Each client can support multiple Shiny apps. The general structure of the Polished configuration files and the Shiny app are:

 - <client_name>
   - polished-<client_name>
   - <shiny_app_1_name>
   - <shiny_app_2_name>
   - ...

### Setting Up

1. Initialize Firebase

In the "<client_name>/polished-<client_name>/" directory, enter the following commands:

Note: you must have nodejs installed

```
# terminal

# if you don't have `firebase-tools` installed, install it globally
npm install -g firebase-tools

# initialize 
firebase init

# check that you want to use firestore and functions
# use JavaScript when prompted
# Do not use eslint when prompted
# Do you want to install dependencies with npm now? Yes
```

Install Firebase functions dependencies 

```
# terminal

npm install --save firebase-admin firebase-functions
```

2. Set up Firebase configuration 

Go to the Firebase web console and create a project named "polished-<client_name>".

In the Firebase Web Console go to the "Database" tab, and enable Firebase.

TODO: create a function to initialize the collections and documents in Firestore


Publish Firestore rules:

```
# R

polished::write_firestore_roles(
  c("<shiny_app_1_name>", "<shiny_app_2_name>", ...)
)
```

```
# terminal
firebase deploy --only firestore:rules
```

Create and deploy Firebase Functions

```
# R
polished::write_firebase_functions()
```

```
# terminal
firebase deploy --only functions
```



# Optional

3. deploy iframe to Firebase hosting

1. update "firebase.json" for the iframe you are going to host.  See "firebase.json" in this
directory for an example. 
2. If this is the first site for this firebase project, set up your new hosting name with the
defualt firebase hosting site.  e.g.

```
# terminal
firebase target:apply hosting auth_custom tychobraauth
```

3. make sure the app is deployed to shinyapps.io

4.  Deploy iframe to Firebase hosting

```
# terminal
firebase deploy --only hosting:auth_custom
```
