
# polished v0.6.0.9000

* fix to allow for multiple custom tabItems on the admin panel 

# polished v0.6.0

* The admin panel query string has been changed from ?page=admin_panel to ?page=admin
* new `get_api_key()` function that will check for the environment variable "POLISHED_API_KEY"
if the api key is not found in the polished options.
* new `polished_config()` function to replace `global_sessions_config()` which has been 
deprecated.
* Bug Fix (#172) - browser previously refreshed when url query or hash parameters changed, but user remained on the Shiny app.  This has been updated to be consistent with normal Shiny behavior (i.e. shiny session does not reload when url query or hash parameters update).
* Added `secure_rmd()`, which can be used to render and secure any Rmarkdown (`.Rmd`) document. Rendering is handled by `rmarkdown::render` and the then the rendered document is secured with `polished` authentication.

# polished v0.5.0

* Added 4 additional [Polished Hosting](https://polished.tech/docs/04-hosting-deploy-app) regions (see documentation for `region` argument of `polished::deploy_app()`)
* App names (i.e. `app_name`) can now include upper case letters & spaces (Example: `app_name = "Example App Name"`)
* added `cache` argument to `deploy_app()` to set whether or not to use a cached build of your Shiny
app on Polished Hosting.
* added `golem_package_name` argument to `deploy_app()` to allow for deploying Golem Shiny apps
to Polished Hosting.
* removed options to pass an "account module" and/or a "splash page module" to the `secure_ui()` and
`secure_server()` functions.  These were experimental arguments for extending polished. We now have a better generalized solution for extending polished -- more to come soon.
* export the `api_list_to_df()` function
* added new `cookie_expires` argument to `global_sessions_config()`, allowing you to set the cookie expiration for app users

# polished v0.4.0

* created API wrapper functions for programmatically managing users, apps, user invites,
roles, etc.  See the new API Wrappers vignette for details (`vignette("api_wrappers", package = "polished")`).
* added 93 new tests for the above mentioned new API wrapper functions.
* removed `api_url` argument from `global_sessions_config()`.  This argument is only used
internally during development, so there is no reason to expose it to package users.
* Bug Fix: fixed check for user already registered during sign in process.
* added `button_color` argument to `sign_in_ui_default()`.
* added `tlmgr` argument to `deploy_app()` which allows support for generating pdf documents from 
Rmarkdown.

# polished v0.3.0

* created new `deploy_app()` function for deploying apps to Polished Hosting.
* removed dependencies on `shinydashboardPlus` due to breaking change with `dashboardHeaderPlus()` and `dashboardPagePlus()`.
* `sign_out_from_shiny()` can now be used in the `session$onSessionEnded()` or `onStop()` to sign the user
out when the user's session ends.
* added support for package dependency detection (#129)
* added cookie options { sameSite: "none", secure: true } when the app is being served over https.  This allows polished authentication to work in an iframe on most browsers.
* added email validation to email inputs in the sign in and registration modules. 
* allow for a function UI be passed to the "ui" argument of `secure_ui()`.
* added "redirect_page" argument to `sign_out_from_shiny()`
* new "is_auth_required" argument added to `global_sessions_config()` which (when set to FALSE) allows users to access your app without being signed in.  By default this argument is set to TRUE. (#109)
* moved toast notification to top (better for mobile) and extended showDuration. (#107)

# polished v0.2.0

* New "account" and "splash" pages.  We will share more on these new pages in upcoming blog posts. 
* Added "is_email_verification_required" argument to `global_sessions_config()` that allows you to disable email verification.
* Admin Panel > User Access * added a checkbox to send an email invite to a newly newly invited user 
* removed usage dashboard from "Admin Panel".  This dashboard has been superseded by the dashboard at
https://dashboard.polished.tech (#102)
* added "background_image" argument to `sign_in_ui_default()` to allow for a full screen image for the sign in page background. 
* only use the "email" sign in provider by default rather than c("google", "email")
* added customizable sign out button to `secure_static()` (#93)
* standardized and documented process for using fully customized sign in and registration pages (#92).  New functions `sign_in_js()` and `sign_in_check_jwt()`, and new vignette on how to use these functions to create fully customized sign in and registration pages.
* add sign_in_module_2 as an alternative premade sign in page.  sign_in_module_2 is designed to look nice when using social sign in
providers (like Google and Microsoft) in addition to email/password.
* Removed sign_in_no_invite_module.  sign_in_module and sign_in_module_2 now have an "is_invite_requirement" argument, so there is no longer a need for a dedicated sign_in_no_invite_module.


# polished v0.1.0

* Added a `NEWS.md` file to track changes to the package.
* Initial CRAN release of polished
