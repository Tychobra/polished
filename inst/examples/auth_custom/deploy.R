

Sys.setenv(R_CONFIG_ACTIVE = "default")

app_config <- config::get(file = "shiny_app/config.yml")
rsconnect::deployApp(
  appDir = "shiny_app",
  account = "tychobra",
  appName = app_config$app_name
)
