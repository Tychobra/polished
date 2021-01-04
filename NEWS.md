# polished 0.3.0.9000

* added support for package dependency detection

# polished v0.2.0.9000

* added cookie options { sameSite: "none", secure: true } when the app is being served over https.  This polished authentication to work in an iframe on most browsers.
* added email validation to email inputs in the sign in and registration modules. 
* allow for a function UI be passed to the "ui" argument of `secure_ui()`.
* added "redirect_page" argument to `sign_out_from_shiny()`
* new "is_auth_required option" to `global_sessions_config()` which (when set to FALSE) allows users to access your app without being signed in.  By default this argument is set to TRUE. (#109)
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
* standarized and documented process for using fully customized sign in and registration pages (#92).  New functions `sign_in_js()` and `sign_in_check_jwt()`, and new vignette on how to use these functions to create fully customized sign in and registration pages.
* add sign_in_module_2 as an alternative premade sign in page.  sign_in_module_2 is designed to look nice when using social sign in
providers (like Google and Microsoft) in addition to email/password.
* Removed sign_in_no_invite_module.  sign_in_module and sign_in_module_2 now have an "is_invite_requirement" argument, so there is no longer a need for a dedicated sign_in_no_invite_module.


# polished v0.1.0

* Added a `NEWS.md` file to track changes to the package.
* Initial CRAN release of polished
