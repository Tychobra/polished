library(shiny)
library(polished)
library(config)
library(shinyjs)

app_config <- config::get()

polished:::set_api_url(
  api_url = "http://0.0.0.0:8080/v1"#,
  #host_api_url = "http://0.0.0.0:8081/v1"
)

#polished:::set_api_url(
#  api_url = "https://auth-api-dev.polished.tech/v1",
#  host_api_url = "https://host-dev.polished.tech/v1"
#)

# configure polished
polished_config(
  app_name = "polished_example_01",
  api_key = app_config$api_key,
  is_2fa_required = TRUE
)
