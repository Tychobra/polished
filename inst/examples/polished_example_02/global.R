library(shiny)
library(polished)
library(config)

app_config <- config::get()

# configure polished
Polished$new(
  app_name = "polished_example_02",
  api_key = app_config$api_key,
  firebase_config = app_config$firebase,
  is_invite_required = FALSE,
  sign_in_providers = c("google"),
  is_email_verification_required = FALSE
)
