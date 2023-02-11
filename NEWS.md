# polished v0.8.1

- bug fix to correct registration flow for email invite required

# polished v0.8.0

- new `add_auth_to_spec()` function to allow you to use the Plumber swagger docs with the new
`auth_filter()` function.
- `max_sessions` argument added to `deploy_app()` which enables the new Polished Hosting load balancer.
- `gh_pat` argument added to `deploy_app()` which can be set to deploy/use private GitHub
packages on Polished Hosting.
- new function `auth_filter()` which makes it very simple to add Polished Auth to
Plumber APIs.
- more user friendly error messages for toast notifications.
- added Hosting support for new "me-west1" region.

# polished v0.7.0

* removed `admin_mode` argument from `polished_config()`.
* added optional `role_name` arg to `add_user_role()`
* `deploy_app()` now throws a more user friendly error message if the app is too large to deploy to Polished Hosting.
* Polished Hosting supports instances with more RAM.  16 and 32 GiB RAM instances are now available.
* the `custom_admin_ui` argument for `secure_ui()` now takes a fully custom shiny app.  This allows users to fully customize their Admin Panel.  Previously you could only add tabs to the existing default Admin Panel, but with this change, you can fully replace the default Admin Panel with a custom Shiny app.
* improved UI of email verification page.
* `update_user()` API wrapper function has been created.
* 2 factor authentication using TOTP has been implemented.  This works with authenticator apps like Google Authenticator.  You can enable it by setting the `is_two_fa_required` argument of `polished_config()` to `TRUE`.
* bug fix - fixed auto email verification check on email verification page.

# polished v0.6.1

* Fixed bug with `is_auth_required` argument for `polished_config()`.

# polished v0.6.0

* major internal refactor to simplify how user sessions are handled.  We remove the reliance
on R6. We now just use a regular base R environment to to hold the configuration and regular R functions (rather than R6 methods) to handle user sessions.  You can now access all `polished` auth configuration from your Shiny app
or other R packages that build upon `polished` via the `polished::.polished` environment. 
* new argument `override_user` added to `secure_server()`. When this argument is set
to `TRUE` (the default), the `session$userData$user()` `polished` user will be accessible in
the `session$user`.  Set this argument to `FALSE` if you are using RStudio Connect or another hosting option that uses the `session$user` and you need access to the value they set for `session$user`. 
* fix to allow for multiple custom `tabItem`s on the Admin Panel.
* The Admin Panel query string has been changed from `?page=admin_panel` to `?page=admin`
* new `get_api_key()` function that will check for the environment variable `POLISHED_API_KEY`.
* new `polished_config()` function to replace `global_sessions_config()` which has been 
deprecated.
* Bug Fix [#172](https://github.com/Tychobra/polished/issues/172) - browser previously refreshed when URL query or hash parameters changed, but user remained on the Shiny app.  This has been updated to be consistent with normal Shiny behavior (i.e. Shiny session does not reload when URL query or hash parameters update).
* Added `secure_rmd()`, which can be used to render and secure any R Markdown (`.Rmd`) document. Rendering is handled by `rmarkdown::render` and the then the rendered document is secured with `polished` authentication.

# polished v0.5.0

* Added 4 additional [Polished Hosting](https://polished.tech/docs/04-hosting-deploy-app) regions (see documentation for `region` argument of `polished::deploy_app()`)
* App names (i.e. `app_name`) can now include upper case letters & spaces (Example: `app_name = "Example App Name"`)
* added `cache` argument to `deploy_app()` to set whether or not to use a cached build of your Shiny
app on [Polished Hosting](https://polished.tech/docs/04-hosting-deploy-app).
* added `golem_package_name` argument to `deploy_app()` to allow for deploying Golem Shiny apps
to [Polished Hosting](https://polished.tech/docs/04-hosting-deploy-app).
* removed options to pass an "account module" and/or a "splash page module" to the `secure_ui()` and
`secure_server()` functions.  These were experimental arguments for extending `polished`. We now have a better generalized solution for extending `polished` -- more to come soon.
* export the `api_list_to_df()` function
* added new `cookie_expires` argument to `global_sessions_config()`, allowing you to set the cookie expiration for app users

# polished v0.4.0

* created API wrapper functions for programmatically managing users, apps, user invites,
roles, etc.  See the new [API Wrappers vignette](https://cran.r-project.org/package=polished/vignettes/api_wrappers.html) for details (`vignette("api_wrappers", package = "polished")`).
* added 93 new tests for the above mentioned new API wrapper functions.
* removed `api_url` argument from `global_sessions_config()`.  This argument is only used
internally during development, so there is no reason to expose it to package users.
* Bug Fix: fixed check for user already registered during sign in process.
* added `button_color` argument to `sign_in_ui_default()`.
* added `tlmgr` argument to `deploy_app()` which allows support for generating pdf documents from 
Rmarkdown.

# polished v0.3.0

* created new `deploy_app()` function for deploying apps to [Polished Hosting](https://polished.tech/docs/04-hosting-deploy-app).
* removed dependencies on `shinydashboardPlus` due to breaking change with `dashboardHeaderPlus()` and `dashboardPagePlus()`.
* `sign_out_from_shiny()` can now be used in the `session$onSessionEnded()` or `onStop()` to sign the user
out when the user's session ends.
* added support for package dependency detection [#129](https://github.com/Tychobra/polished/pull/129)
* added cookie options `{ sameSite: "none", secure: true }` when the app is being served over https.  This allows `polished` authentication to work in an iframe on most browsers.
* added email validation to email inputs in the sign in and registration modules. 
* allow for a function UI be passed to the "ui" argument of `secure_ui()`.
* added `redirect_page` argument to `sign_out_from_shiny()`
* new `is_auth_required` argument added to `global_sessions_config()` which (when set to `FALSE`) allows users to access your app without being signed in.  By default this argument is set to `TRUE`. [#109](https://github.com/Tychobra/polished/pull/109)
* moved toast notification to top (better for mobile) and extended `showDuration`. [#107](https://github.com/Tychobra/polished/pull/107)

# polished v0.2.0

* New "account" and "splash" pages.  We will share more on these new pages in upcoming [blog posts](https://www.tychobra.com/posts/). 
* Added `is_email_verification_required` argument to `global_sessions_config()` that allows you to disable email verification.
* Admin Panel > User Access > Add User: added checkbox to send an email invite to a newly invited user 
* removed usage dashboard from Admin Panel.  This dashboard has been superseded by the dashboard at
https://dashboard.polished.tech [#102](https://github.com/Tychobra/polished/pull/102)
* added `background_image` argument to `sign_in_ui_default()` to allow for a full screen image for the sign in page background. 
* only use the `"email"` sign in provider by default rather than `c("google", "email")`.
* added customizable sign out button to `secure_static()` [#93](https://github.com/Tychobra/polished/pull/93)
* standardized and documented process for using fully customized sign in and registration pages [#92](https://github.com/Tychobra/polished/pull/92).  New functions `sign_in_js()` and `sign_in_check_jwt()`, and new vignette on how to use these functions to create fully customized sign in and registration pages.
* add `sign_in_module_2` as an alternative premade sign in page.  `sign_in_module_2` is designed to look nice when using social sign in providers (like Google and Microsoft) in addition to email/password.
* Removed `sign_in_no_invite_module`.  `sign_in_module` and `sign_in_module_2` now have an `is_invite_requirement` argument, so there is no longer a need for a dedicated `sign_in_no_invite_module`.


# polished v0.1.0

* Added a `NEWS.md` file to track changes to the package.
* Initial CRAN release of `polished`
