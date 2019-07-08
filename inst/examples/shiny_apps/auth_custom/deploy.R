remotes::install_github(
  "tychobra/polished",
  force = TRUE
)


Sys.setenv(R_CONFIG_ACTIVE = "default")

app_config <- config::get(file = "shiny-app/config.yml")
rsconnect::deployApp(
  appDir = "shiny-app",
  account = "tychobra",
  appName = app_config$app_name,
  forceUpdate = TRUE
)
