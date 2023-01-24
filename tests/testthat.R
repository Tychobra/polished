library(testthat)
library(polished)
library(httr)

## force tests to be executed if in dev release which we define as
## having a sub-release, eg 0.9.15.5 is one whereas 0.9.16 is not
if (length(strsplit(packageDescription("polished")$Version, "\\.")[[1]]) > 3) {
  # this is the dev version, so do not skip tests
  run_tests <- TRUE
} else {
  # this is on CRAN, so skip tests
  run_tests <- FALSE
}

if (isTRUE(run_tests)) {
  test_check("polished")
  #testthat::test_local()
}

