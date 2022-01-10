
# run this function to render your .Rmd with polished authentication
polished::secure_rmd(
  rmd_file_path = "<path to your .Rmd file>",

  # if your Polished API key is not set as an R environment variable, then you
  # can it here.
  #polished_config_args = list(
  #  api_key = "<your Polished API key>"
  #)
)
