
if (file.exists("config.yml")) {
  the_config <- config::get()

  polished::set_api_key(the_config$api_key)
}


polished:::set_api_url(
  api_url = "https://auth-api-dev.polished.tech/v1",
  #api_url = "http://0.0.0.0:8080/v1",
  host_api_url = "https://host-dev.polished.tech/v1"#,
  #host_api_url = "http://0.0.0.0:8081/v1"
)
