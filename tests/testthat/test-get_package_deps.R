
# setup a temporary appdir
tpdir <- normalizePath(tempdir())

# remove any existing deps files
apppath <- fs::path_package("polished", "examples/test_app")

# copy to temp dir
fs::dir_copy(apppath, fs::path(tpdir, "test_app"), overwrite = TRUE)
app <- file.path(tpdir, "test_app")

test_that("test creation of deps.yaml", {

  withr::with_dir(app, {

    deps_list <- polished:::get_package_deps(app_dir = app)

    testthat::expect_equal(deps_list, yaml::read_yaml(fs::path_package("polished", "testfiles/deps_no_polished.yaml")))

  })

})

# cleanup
fs::dir_delete(tpdir)
rm(tpdir, apppath, app)



