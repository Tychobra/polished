library(testthat)
library(polished)
library(httr)

## force tests to be executed if in dev release which we define as
## having a sub-release, eg 0.9.15.5 is one whereas 0.9.16 is not
if (length(strsplit(packageDescription("polished")$Version, "\\.")[[1]]) > 3) {
  Sys.setenv("SKIP_POLISHED_TESTS"="false")
} else {
  Sys.setenv("SKIP_POLISHED_TESTS"="true")
}

if (identical(Sys.getenv("SKIP_POLISHED_TESTS"), "true")) {
  test_check("polished")
  #testthat::test_local()
}

