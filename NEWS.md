# v0.2.0.9000



# v0.2.0

- New "account" and "splash" pages.  We will share more on these new pages in upcoming blog posts. 
- Added "is_email_verification_required" argument to `global_sessions_config()` that allows you to disable email verification.
- Admin Panel > User Access - added a checkbox to send an email invite to a newly newly invited user 
- removed usage dashboard from "Admin Panel".  This dashboard has been superseded by the dashboard at
https://dashboard.polished.tech (#102)
- added "background_image" argument to `sign_in_ui_default()` to allow for a full screen image for the sign in page background. 
- only use the "email" sign in provider by default rather than c("google", "email")
- added customizable sign out button to `secure_static()` (#93)
- standarized and documented process for using fully customized sign in and registration pages (#92).  New functions `sign_in_js()` and `sign_in_check_jwt()`, and new vignette on how to use these functions to create fully customized sign in and registration pages.
- add sign_in_module_2 as an alternative premade sign in page.  sign_in_module_2 is designed to look nice when using social sign in
providers (like Google and Microsoft) in addition to email/password.
- Removed sign_in_no_invite_module.  sign_in_module and sign_in_module_2 now have an "is_invite_requirement" argument, so there is no longer a need for a dedicated sign_in_no_invite_module.


# v0.1.0

- Initial CRAN release of polished
