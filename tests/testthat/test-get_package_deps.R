
# setup a temporary appdir
tpdir <- normalizePath(tempdir())

# remove any existing deps files
apppath <- fs::path_package("polished", "examples/test_app")

# copy to temp dir
fs::dir_copy(apppath, fs::path(tpdir, "test_app"), overwrite = TRUE)
app <- file.path(tpdir, "test_app")

test_that("test creation of deps.yaml", {



  deps_list <- polished:::get_package_deps(app_dir = app)

  testthat::expect_equal(deps_list[[1]]$Package, "shiny")
  testthat::expect_equal(deps_list[[2]]$Package, "config")

})

# cleanup
fs::dir_delete(tpdir)
rm(tpdir, apppath, app)



