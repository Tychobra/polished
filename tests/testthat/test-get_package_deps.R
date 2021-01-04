
# setup a temporary appdir
tpdir <- normalizePath(tempdir())

# remove any existing deps files
apppath <- fs::path_package("polished", "examples/test_app")

# copy to temp dir
fs::dir_copy(apppath, fs::path(tpdir, "test_app"), overwrite = TRUE)
app <- file.path(tpdir, "test_app")

test_that("test creation of deps.yaml", {

  withr::with_dir(app, {

    polished:::get_package_deps(path = app)

    yaml_test <- file.exists(file.path(app, "deps.yaml"))
    testthat::expect_true(yaml_test)
    yaml_content <- yaml::read_yaml(file.path(app, "deps.yaml"))
    testthat::expect_equal(yaml_content, yaml::read_yaml(fs::path_package("polished", "testfiles/deps_no_polished.yaml")))

  })

})

# cleanup
fs::dir_delete(tpdir)
rm(tpdir, apppath, app)



