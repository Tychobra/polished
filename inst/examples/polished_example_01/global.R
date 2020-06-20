library(shiny)
#detach("package:polished", unload=TRUE)
#remotes::install_github('tychobra/polished', ref = 'fa9004208c54369b0288198f9e7fb60558f4147b')
library(polished)
library(config)


app_config <- config::get()

# configure polished
global_sessions_config(
  app_name = "polished_example_01",
  api_key = app_config$api_key,
  #api_url = "http://localhost:8080",
  firebase_config = app_config$firebase,
  sign_in_providers = c("google", "email")
)
