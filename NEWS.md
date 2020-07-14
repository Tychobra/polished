# v0.1.0.9000

- added "background_image" argument to `sign_in_ui_default()` to allow for a full screen image for the sign in page background. 
- only use the "email" sign in provider by default rather than c("google", "email")
- add customizable sign out button to secure_static #93
- standarized and documented process for using fully customized sign in and registration pages #92
- add sign_in_module_2 as an alternative premade sign in page - this required editing and generalizing several related functions.
Deprecate sign_in_no_invite_module, have other default pages work with or without an invite requirement


# v0.1.0

- Initial CRAN release of polished
