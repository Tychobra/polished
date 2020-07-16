# v0.1.0.9000

- added "background_image" argument to `sign_in_ui_default()` to allow for a full screen image for the sign in page background. 
- only use the "email" sign in provider by default rather than c("google", "email")
- add customizable sign out button to `secure_static()` #93
- standarized and documented process for using fully customized sign in and registration pages #92.  New functions `sign_in_js()` and `sign_in_check_jwt()`, and new vignette on how to use these functions to create fully customized sign in and registration pages.
- add sign_in_module_2 as an alternative premade sign in page.
- Deprecated sign_in_no_invite_module.  sign_in_module and sign_in_module_2 can now work with or without an invite requirement, so there is no longer a need for a dedicated sign_in_no_invite_module.


# v0.1.0

- Initial CRAN release of polished
