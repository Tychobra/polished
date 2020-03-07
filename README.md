# polished <img src="inst/assets/images/polished_hex.png" align="right" width="120" />

[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing) [![Travis-CI Build Status](https://travis-ci.org/Tychobra/polished.svg?branch=master)](https://travis-ci.org/tychobra/polished)

Authentication and user administration for Shiny apps.  `polished` provides a way to secure your Shiny application behind an authentication layer.  It also provides a UI for controlling user access and monitoring user activitiy. 

Sign in to a [Live Demo Shiny App](https://tychobra.shinyapps.io/polished_example_01) with the following:

 - email: demo@tychobra.com
 - password: polished

Check out the [introducing polished blog post](https://www.tychobra.com/posts/2019_08_27_announcing_polished/) for a high level overview and video.

Warning: there will be many breaking changes before this package matures to version 1.0.0

### Requirements

- R
- one or more Shiny apps
- a [Firebase](https://firebase.google.com/) account
- a PostgreSQL database

### `polished` installation

```
# R

remotes::install_github("tychobra/tychobratools")
remotes::install_github("tychobra/polished")
```

### Initial Set Up

1. Set up your Firebase project. Go to [https://firebase.google.com/](https://firebase.google.com/) and create a firebase project named "polished-<project_name>".  Open your new Firebase project and:
   - go to the "Authentication" page "Sign-in method" tab and enable "Email/Password" sign in. See the below screenshot:
   ![](https://res.cloudinary.com/dxqnb8xjb/image/upload/v1573001859/firabse-auth_roq6yv.png)

2. Set up PostgreSQL "polished" schema.  This schema stores your users, apps, and information about which users are authorized to access which apps.  To create this schema you must have a PostgreSQL database that you can connect to.

```
# R

# connect to your PostgreSQL database
db_conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  <your db connection credentials>
)

# If this is your first Shiny app using polished, create the "polished" schema.
# Warning: if you already have a polished schema this function will overwrite your existing schema with empty tables.
polished::create_schema(db_conn)

# add the first user to your first app
# I always add myself first using this function, and then I add other additional users via 
# the "Polished Admin > User Access" page
polished::create_app_user(db_conn, app_name = "<your app name>", email = "<your email>", is_admin = TRUE)
```

3. Secure Your Shiny App

To secure your Shiny app, execute the `global_sessions_config()` in "global.R", pass your Shiny ui to `secure_ui()`, and your Shiny server to `secure_server()`.  See the the documentation of `global_sessions_config()`, `secure_ui()`, and `secure_server()` for details.

```
# R
?global_sessions_config
?secure_ui
?secure_server
```

You can find a few full working example in the "inst/examples/" directory in this package.  

### Additional Options

#### 1. Customize the Sign In / Register UI

Companies often want to add their logos and branding to the sign in and register pages.  With polished, you can easily customize these pages.  Just pass your custom UI to the `sign_in_page_ui` argument of `secure_ui()`.  

Sign in to a [Live Example](https://tychobra.shinyapps.io/custom_sign_in) with the following:

 - email: demo@tychobra.com
 - password: polished

The code for the above example is available in the "inst/examples/custom_sign_in/" directory.  To get this example working, you will need to update the "config.yml" with your Firebase credentials. 

#### 2. Add custom tabs to the Polished Admin shinydashboard

You can add custom tabs to the admin dashboard by passing the ui and server code to the `secure_ui()` and `secure_server()` functions.  Example coming soon.

#### 3. Apps Dashboard

Create a Shiny dashboard of your Shiny dashboards/apps.  Example coming soon.

