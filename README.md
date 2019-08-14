# polished

[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)

Authentication and administration for Shiny apps.  Polished provides a way to secure your Shiny application behind an authentication layer.  It also provides a UI for controlling user access and monitoring user activitiy. 

## Getting Started

We recommend the following folder structure:

- <project_name>/
   - polished-<project_name>/
   - <shiny_app_1>/
   - <shiny_app_2>/
   - ...

The "polished-<project_name>" folder contains all the `polished` project configuration.  "<shiny_app_1>", "<shiny_app_2>", and "..." (other Shiny apps) are the Shiny apps that use the polished configuration set in "polished-<project_name>".

The Shiny apps all use the same email/password for authentication.  e.g. if user `A` is authorized to sign into "<shiny_app_1>" and "<shiny_app_2>", user `A` would use the same email and password to sign into both Shiny apps 1 and 2.  User authorization is then set at a per Shiny app level.  So, for example, an admin could change user `A`s authorization such that user `A` could only access "<shiny_app_1>". 

You can have as many Shiny apps in the "<project_name>" folder as you want.  At Tychobra, we build Shiny apps for many different companies, so in our work, each client company usually gets their own separate "<project_name>" directory containing one or more Shiny apps.  

### Requirements

- R
- one or more Shiny app(s)
- [nodejs](https://nodejs.org/en/)
- a [Firebase](https://firebase.google.com/) account

### `polished` installation

```
# R

# install remotes and packages if needed
install.packages("remotes") 
install.packages("shinydashboard")
remotes::install_github("tychobra/tychobratools")

remotes::install_github("tychobra/polished")
```

### Initial Set Up

1. Set up your Firebase project. Go to [https://firebase.google.com/](https://firebase.google.com/) and create a firebase project named "polished-<project_name>".  Open your new Firebase project and:
   - go to the "Authentication" page "Sign-in method" tab and enable "Email/Password" sign in.
   - go to the "Database" tab, and click "Create Database" to create a Firestore database.  Start the database in "test mode".  We will secure the database in a later step.

2. Set up initial user in Firestore.
TODO: create function to somehow automate this process.  Probably can do this with a new Firebase function??
For now, In the Firebase web UI of your Firebase project, go the the "Database" tab and create a new "apps/{your Shiny app name}/users/{your email address} document with the following fields:
   - email: string - "<your_email_address>"
   - app_name: string - "<your_shiny_app_name>"
   - time_created: timestamp - fill it in with some time today
   - invite_status: string - "pending"
   - is_admin: boolean - `true`

3. Organize your Shiny app(s) in accordance with the folder structure from the "Getting Started" section

4. Set up the "<project_name>/polished-<project_name>" folder.

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

Open R and set your working directory to the "polished-<project_name>" folder.

```
# R

polished::write_firestore_rules(
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

## Secure Your Shiny App

To secure your Shiny app you simply pass your Shiny ui to `secure_ui()` and your Shiny server to `secure_server()`.  Additionally you need to pass the firebase configuration and the app name to `secure_ui()` and `secure_server()`.    

e.g. here is a complete secure Shiny app less the correct Firebase configuation.

```
global <- function() {
  library(shiny)
  library(polished)
  
  my_config <- config::get()
}

ui <- h1("Hellow World")

server <- function(input, output, session) {}

your_secure_ui <- secure_ui(
  ui,
  firebase_config = my_config$firebase,
  app_name = "your_app_name"
)

your_secure_server <- secure_server(
  server,
  firebase_functions_url = my_config$firebase_functions_url,
  app_name = "your_app_name"
)

shinyApp(your_secure_ui, your_secure_server, onStart = global())```
```

You can find full working examples with properly configured "config.yml" files in the "inst/examples/" directory in this package.  The examples in "inst/examples/" use our preferred file + directory structure for organizaing Shiny apps.

### Additional Options

#### 1. Customize the Sign In / Register UI

Companies often want to add their logos and branding to the sign in and register pages.  With polished, you can easily customize these pages.  Just pass your custom UI to the `sign_in_page_ui` argument of `secure_ui()`.  You can find an example of a customized sing in and register UI in the "inst/examples/auth_custom" Shiny app that is shipped with `polished`.

#### 2. deploy iframe to Firebase hosting

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
