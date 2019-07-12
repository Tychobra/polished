# polished

Authentication and administration for Shiny apps.  Polished provides a way to secure your Shiny application behind an authentication layer.  It also provides a UI for controlling user access and monitoring user activitiy. 

## Getting Started

We recommend the following folder structure:

- <project_name>
   - polished-<project_name>
   - <shiny_app_1>
   - <shiny_app_2>
   - ...

The "polished-<project_name>" folder contains all the `polished` project configuration.  "<shiny_app_1>", "<shiny_app_2>", and "..." (other Shiny apps) are the Shiny apps that use this polished project.

The Shiny apps all use the same email/password for authentication.  e.g. if user `A` is authorized to sign into "<shiny_app_1>" and "<shiny_app_2>", user `A` would use the same email and password to sign into both Shiny apps 1 and 2.  User authorization is then set at a per Shiny app level.  So, for example, an admin could change user `A`s authorization such that user `A` could only access "<shiny_app_1>". 

You can have as many Shiny apps in the "<project_name>" folder as you want.  At Tychobra, we build Shiny apps for many different companies, so in our work, each client comapny usually gets their own separate "<project_name>" directory containing one or more Shiny apps.  

### Requirements

- R
- one or more Shiny app(s)
- `polished`

```
# install polished
remotes::install_github("tychobra/polished")
```

- [nodejs](https://nodejs.org/en/)
- a [Firebase](https://firebase.google.com/) account

### Initial Set Up

1. Set up your Firebase project

Go to [https://firebase.google.com/](https://firebase.google.com/) and create a firebase project named "polished-<project_name>".

Open your new Firebase project and
 - go to the "Authentication" page "Sign-in method" tab and enable "Email/Password" sign in.
 - go to the "Database" tab, and enable Firestore.  Make sure the Firestore rules allow all read writes during this initial set up.

2. Organize your Shiny app(s) in accordance with the folder structure from the "Getting Started" section

3. Set up the "<project_name>/polished-<project_name>" folder.

Move to the "<project_name>" folder.

```
# terminal

cd <project_name>

# make polished folder and move to it
mkdir polished-<project_name> 
cd polished-<project_name>

# if you don't have `firebase-tools` installed, install it globally
npm install -g firebase-tools

# initialize 
firebase init
```

Enter the following in the command line prompts:
 - Which Firebase CLI features do you want...? Firestore and Functions
 - Select a default Firebase project for this directory: choose the Firebase project id from step 1
 - What file should be used for Firestore Rules? use the default
 - What file should be used for Firestore indexes? use the default
 - What language would you like to use to write Cloud Functions? JavaScript
 - Do you want to use ESLint to catch probable bugs and enforce style? N
 - Do you want to install dependencies with npm now? Y

Your "polished-<project_name>" folder should now look like this:
 - firebase.json
 - firestore.indexes.json
 - firestore.rules
 - functions/
 
Next Install Firebase functions dependencies 

```
# terminal

cd functions
npm install --save firebase-admin firebase-functions
```

Publish Firestore rules:

Open R and set your working directory set to the "polished-<project_name>" folder.

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
