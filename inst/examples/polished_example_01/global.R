library(shiny)
library(polished)
library(config)


app_config <- config::get()

# configure polished
global_sessions_config(
  app_name = "polished_example_01",
  api_key = "ZkYyWz9giNhTTc4va5nJ22G3VpGUIU4eTw",
  api_url = "http://localhost:8080"
)
